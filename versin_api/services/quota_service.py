import logging

from datetime import datetime, timedelta, timezone

import redis.asyncio as redis

from redis.exceptions import RedisError

from core.config import settings


class QuotaService:
    # ============================================================
    # FAIXAS DE USO
    # ============================================================

    WARNING_PERCENTAGE = 80.0
    CRITICAL_PERCENTAGE = 90.0
    BLOCKED_PERCENTAGE = 100.0

    # ============================================================
    # CICLOS / LIMPEZA
    # ============================================================

    MONTHLY_CLEANUP_GRACE_SECONDS = (
        60 * 60 * 24 * 7
    )

    DAILY_CLEANUP_GRACE_SECONDS = (
        60 * 60 * 24
    )

    # ============================================================
    # USUÁRIO
    # ============================================================

    MAX_USER_ID_LENGTH = 128

    # ============================================================
    # SCRIPT ATÔMICO DE REGISTRO
    # ============================================================
    #
    # Atualiza:
    #
    # 1. quota mensal do usuário;
    # 2. quota global diária.
    #
    # Tudo em uma única operação no Redis.
    #
    # Também garante TTL caso a chave esteja sem expiração.
    #
    # ============================================================

    _REGISTER_USAGE_SCRIPT = """
local user_key = KEYS[1]
local global_key = KEYS[2]

local tokens = tonumber(ARGV[1])
local user_ttl = tonumber(ARGV[2])
local global_ttl = tonumber(ARGV[3])

local user_usage = redis.call(
    'INCRBY',
    user_key,
    tokens
)

local current_user_ttl = redis.call(
    'TTL',
    user_key
)

if current_user_ttl < 0 then
    redis.call(
        'EXPIRE',
        user_key,
        user_ttl
    )
end

local global_usage = redis.call(
    'INCRBY',
    global_key,
    tokens
)

local current_global_ttl = redis.call(
    'TTL',
    global_key
)

if current_global_ttl < 0 then
    redis.call(
        'EXPIRE',
        global_key,
        global_ttl
    )
end

return {
    user_usage,
    global_usage
}
"""

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        monthly_token_limit: int | None = None,
        global_daily_token_limit: int | None = None,
    ):
        self.logger = logging.getLogger(
            __name__
        )

        # ========================================================
        # REDIS
        # ========================================================

        if not settings.REDIS_URL:
            raise ValueError(
                "REDIS_URL não configurada."
            )

        # ========================================================
        # LIMITES
        # ========================================================

        self.monthly_token_limit = (
            monthly_token_limit
            if monthly_token_limit is not None
            else settings.AI_MONTHLY_TOKEN_LIMIT
        )

        self.global_daily_token_limit = (
            global_daily_token_limit
            if global_daily_token_limit is not None
            else settings.AI_GLOBAL_DAILY_TOKEN_LIMIT
        )

        if (
            self.monthly_token_limit
            <= 0
        ):
            raise ValueError(
                (
                    "AI_MONTHLY_TOKEN_LIMIT "
                    "deve ser maior que zero."
                )
            )

        if (
            self.global_daily_token_limit
            <= 0
        ):
            raise ValueError(
                (
                    "AI_GLOBAL_DAILY_TOKEN_LIMIT "
                    "deve ser maior que zero."
                )
            )

        # ========================================================
        # CLIENTE REDIS
        # ========================================================

        self.redis = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,

            socket_connect_timeout=10,
            socket_timeout=10,

            retry_on_timeout=True,

            health_check_interval=30,
        )

        self._redis_available = True

    # ============================================================
    # TESTAR REDIS
    # ============================================================

    async def check_connection(
        self,
    ) -> bool:
        try:
            result = (
                await self.redis.ping()
            )

            self._redis_available = bool(
                result
            )

            if self._redis_available:
                self.logger.info(
                    (
                        "[QUOTA] Redis "
                        "conectado com sucesso."
                    )
                )

            return (
                self._redis_available
            )

        except RedisError as error:
            self._redis_available = False

            self.logger.error(
                (
                    "[QUOTA] Redis indisponível | "
                    "type=%s | detail=%s"
                ),
                type(error).__name__,
                error,
            )

            return False

        except Exception as error:
            self._redis_available = False

            self.logger.exception(
                (
                    "[QUOTA] Erro inesperado "
                    "ao testar Redis: %s"
                ),
                error,
            )

            return False

    # ============================================================
    # ESTADO DO REDIS
    # ============================================================

    @property
    def redis_available(
        self,
    ) -> bool:
        return (
            self._redis_available
        )

    # ============================================================
    # GARANTIR CONEXÃO
    # ============================================================

    async def ensure_connection(
        self,
    ) -> bool:
        if self._redis_available:
            return True

        return await (
            self.check_connection()
        )

    # ============================================================
    # DATA UTC
    # ============================================================

    @staticmethod
    def _now() -> datetime:
        return datetime.now(
            timezone.utc
        )

    # ============================================================
    # INÍCIO DO MÊS
    # ============================================================

    def _get_current_month_start(
        self,
    ) -> datetime:
        now = self._now()

        return datetime(
            year=now.year,
            month=now.month,
            day=1,
            tzinfo=timezone.utc,
        )

    # ============================================================
    # PRÓXIMO MÊS
    # ============================================================

    def _get_next_month_start(
        self,
    ) -> datetime:
        now = self._now()

        if now.month == 12:
            return datetime(
                year=now.year + 1,
                month=1,
                day=1,
                tzinfo=timezone.utc,
            )

        return datetime(
            year=now.year,
            month=now.month + 1,
            day=1,
            tzinfo=timezone.utc,
        )

    # ============================================================
    # PRÓXIMO DIA UTC
    # ============================================================

    def _get_next_day_start(
        self,
    ) -> datetime:
        tomorrow = (
            self._now()
            + timedelta(
                days=1
            )
        )

        return datetime(
            year=tomorrow.year,
            month=tomorrow.month,
            day=tomorrow.day,
            tzinfo=timezone.utc,
        )

    # ============================================================
    # SEGUNDOS ATÉ
    # ============================================================

    def _seconds_until(
        self,
        target: datetime,
    ) -> int:
        seconds = int(
            (
                target
                - self._now()
            ).total_seconds()
        )

        return max(
            seconds,
            0,
        )

    # ============================================================
    # TTL MENSAL
    # ============================================================

    def _get_monthly_key_ttl(
        self,
    ) -> int:
        return max(
            1,
            (
                self._seconds_until(
                    self._get_next_month_start()
                )
                + self.MONTHLY_CLEANUP_GRACE_SECONDS
            ),
        )

    # ============================================================
    # TTL DIÁRIO
    # ============================================================

    def _get_daily_key_ttl(
        self,
    ) -> int:
        return max(
            1,
            (
                self._seconds_until(
                    self._get_next_day_start()
                )
                + self.DAILY_CLEANUP_GRACE_SECONDS
            ),
        )

    # ============================================================
    # METADADOS MENSAIS
    # ============================================================

    def _get_monthly_period_metadata(
        self,
    ) -> dict:
        now = self._now()

        period_start = (
            self._get_current_month_start()
        )

        renews_at = (
            self._get_next_month_start()
        )

        renews_in_seconds = max(
            0,
            int(
                (
                    renews_at
                    - now
                ).total_seconds()
            ),
        )

        renews_in_hours = (
            renews_in_seconds
            // 3600
        )

        renews_in_days = (
            (
                renews_in_seconds
                + 86399
            )
            // 86400
        )

        return {
            "period": "monthly",

            "provider": "groq",

            "billing_cycle_anchor": (
                "first_day_of_month"
            ),

            "renewal_timezone": "UTC",

            "period_start": (
                period_start.isoformat()
            ),

            "renews_at": (
                renews_at.isoformat()
            ),

            "renews_in_seconds": (
                renews_in_seconds
            ),

            "renews_in_hours": (
                renews_in_hours
            ),

            "renews_in_days": (
                renews_in_days
            ),
        }

    # ============================================================
    # CHAVE MENSAL DO USUÁRIO
    # ============================================================

    def _get_month_key(
        self,
        user_id: str,
    ) -> str:
        month = (
            self._now()
            .strftime(
                "%Y-%m"
            )
        )

        return (
            f"ai_quota:user:"
            f"{user_id}:"
            f"{month}"
        )

    # ============================================================
    # CHAVE GLOBAL DIÁRIA
    # ============================================================

    def _get_global_day_key(
        self,
    ) -> str:
        day = (
            self._now()
            .strftime(
                "%Y-%m-%d"
            )
        )

        return (
            f"ai_quota:global:"
            f"{day}"
        )

    # ============================================================
    # VALIDAR USUÁRIO
    # ============================================================

    @classmethod
    def _validate_user_id(
        cls,
        user_id: str,
    ) -> str:
        if not isinstance(
            user_id,
            str,
        ):
            raise ValueError(
                "user_id inválido."
            )

        normalized = (
            user_id.strip()
        )

        if not normalized:
            raise ValueError(
                "user_id inválido."
            )

        if (
            len(normalized)
            >
            cls.MAX_USER_ID_LENGTH
        ):
            raise ValueError(
                "user_id inválido."
            )

        return normalized

    # ============================================================
    # NORMALIZAR TOKENS
    # ============================================================

    @staticmethod
    def _normalize_tokens(
        tokens,
    ) -> int:
        try:
            return max(
                int(
                    tokens
                    or 0
                ),
                0,
            )

        except (
            TypeError,
            ValueError,
        ):
            return 0

    # ============================================================
    # USO MENSAL
    # ============================================================

    async def get_usage(
        self,
        user_id: str,
    ) -> int:
        user_id = (
            self._validate_user_id(
                user_id
            )
        )

        key = self._get_month_key(
            user_id
        )

        try:
            value = (
                await self.redis.get(
                    key
                )
            )

            self._redis_available = True

            return self._normalize_tokens(
                value
            )

        except RedisError as error:
            self._redis_available = False

            self.logger.error(
                (
                    "[QUOTA] Erro ao consultar "
                    "quota mensal | "
                    "type=%s | detail=%s"
                ),
                type(error).__name__,
                error,
            )

            # ====================================================
            # FAIL OPEN
            # ====================================================

            return 0

    # ============================================================
    # USO GLOBAL DIÁRIO
    # ============================================================

    async def get_global_daily_usage(
        self,
    ) -> int:
        key = (
            self._get_global_day_key()
        )

        try:
            value = (
                await self.redis.get(
                    key
                )
            )

            self._redis_available = True

            return self._normalize_tokens(
                value
            )

        except RedisError as error:
            self._redis_available = False

            self.logger.error(
                (
                    "[QUOTA] Erro ao consultar "
                    "quota global diária | "
                    "type=%s | detail=%s"
                ),
                type(error).__name__,
                error,
            )

            return 0

    # ============================================================
    # RESTANTE MENSAL
    # ============================================================

    async def get_remaining(
        self,
        user_id: str,
    ) -> int:
        usage = await self.get_usage(
            user_id
        )

        return max(
            0,
            (
                self.monthly_token_limit
                - usage
            ),
        )

    # ============================================================
    # RESTANTE GLOBAL
    # ============================================================

    async def get_global_daily_remaining(
        self,
    ) -> int:
        usage = (
            await self
            .get_global_daily_usage()
        )

        return max(
            0,
            (
                self.global_daily_token_limit
                - usage
            ),
        )

    # ============================================================
    # PERCENTUAL
    # ============================================================

    @staticmethod
    def _calculate_percentage(
        usage: int,
        limit: int,
    ) -> float:
        if limit <= 0:
            return 100.0

        percentage = (
            usage
            / limit
            * 100
        )

        return min(
            100.0,
            max(
                0.0,
                percentage,
            ),
        )

    # ============================================================
    # PERCENTUAL DO USUÁRIO
    # ============================================================

    async def get_usage_percentage(
        self,
        user_id: str,
    ) -> float:
        usage = await self.get_usage(
            user_id
        )

        return self._calculate_percentage(
            usage,
            self.monthly_token_limit,
        )

    # ============================================================
    # PERCENTUAL GLOBAL
    # ============================================================

    async def get_global_daily_percentage(
        self,
    ) -> float:
        usage = (
            await self
            .get_global_daily_usage()
        )

        return self._calculate_percentage(
            usage,
            self.global_daily_token_limit,
        )

    # ============================================================
    # VERIFICAR LIMITE INDIVIDUAL
    # ============================================================

    async def check_user_limit(
        self,
        user_id: str,
        estimated_tokens: int = 0,
    ) -> bool:
        usage = await self.get_usage(
            user_id
        )

        estimated_tokens = (
            self._normalize_tokens(
                estimated_tokens
            )
        )

        projected_usage = (
            usage
            + estimated_tokens
        )

        # ========================================================
        # Permite chegar exatamente ao limite.
        #
        # Exemplo:
        #
        # 48.000 usados
        # + 2.000 estimados
        # = 50.000
        #
        # Ainda pode executar.
        # ========================================================

        return (
            projected_usage
            <= self.monthly_token_limit
        )

    # ============================================================
    # VERIFICAR LIMITE GLOBAL
    # ============================================================

    async def check_global_limit(
        self,
        estimated_tokens: int = 0,
    ) -> bool:
        usage = (
            await self
            .get_global_daily_usage()
        )

        estimated_tokens = (
            self._normalize_tokens(
                estimated_tokens
            )
        )

        projected_usage = (
            usage
            + estimated_tokens
        )

        return (
            projected_usage
            <= self.global_daily_token_limit
        )

    # ============================================================
    # VERIFICAR SE PODE USAR IA
    # ============================================================

    async def check_limit(
        self,
        user_id: str,
        estimated_tokens: int = 0,
    ) -> bool:
        user_allowed = (
            await self.check_user_limit(
                user_id=user_id,
                estimated_tokens=(
                    estimated_tokens
                ),
            )
        )

        if not user_allowed:
            return False

        return await (
            self.check_global_limit(
                estimated_tokens=(
                    estimated_tokens
                )
            )
        )

    # ============================================================
    # LIMITE MENSAL ATINGIDO
    # ============================================================

    async def is_limit_reached(
        self,
        user_id: str,
    ) -> bool:
        usage = await self.get_usage(
            user_id
        )

        return (
            usage
            >= self.monthly_token_limit
        )

    # ============================================================
    # LIMITE GLOBAL ATINGIDO
    # ============================================================

    async def is_global_limit_reached(
        self,
    ) -> bool:
        usage = (
            await self
            .get_global_daily_usage()
        )

        return (
            usage
            >= self.global_daily_token_limit
        )

    # ============================================================
    # REGISTRAR CONSUMO
    # ============================================================

    async def register_usage(
        self,
        user_id: str,
        input_tokens: int = 0,
        output_tokens: int = 0,
    ) -> int:
        user_id = (
            self._validate_user_id(
                user_id
            )
        )

        input_tokens = (
            self._normalize_tokens(
                input_tokens
            )
        )

        output_tokens = (
            self._normalize_tokens(
                output_tokens
            )
        )

        total_tokens = (
            input_tokens
            + output_tokens
        )

        # ========================================================
        # NADA PARA REGISTRAR
        # ========================================================

        if total_tokens <= 0:
            return await self.get_usage(
                user_id
            )

        # ========================================================
        # CHAVES
        # ========================================================

        user_key = (
            self._get_month_key(
                user_id
            )
        )

        global_key = (
            self._get_global_day_key()
        )

        # ========================================================
        # TTLS
        # ========================================================

        user_ttl = (
            self._get_monthly_key_ttl()
        )

        global_ttl = (
            self._get_daily_key_ttl()
        )

        try:
            # ====================================================
            # REGISTRO ATÔMICO
            # ====================================================

            result = await self.redis.eval(
                self._REGISTER_USAGE_SCRIPT,
                2,
                user_key,
                global_key,
                total_tokens,
                user_ttl,
                global_ttl,
            )

            # ====================================================
            # NORMALIZAR RESULTADO
            # ====================================================

            user_usage = (
                self._normalize_tokens(
                    result[0]
                    if (
                        isinstance(
                            result,
                            (list, tuple),
                        )
                        and len(result) > 0
                    )
                    else 0
                )
            )

            global_usage = (
                self._normalize_tokens(
                    result[1]
                    if (
                        isinstance(
                            result,
                            (list, tuple),
                        )
                        and len(result) > 1
                    )
                    else 0
                )
            )

            self._redis_available = True

            # ====================================================
            # LOG
            # ====================================================

            self.logger.info(
                (
                    "[QUOTA] Uso registrado | "
                    "user=%s | "
                    "input=%s | "
                    "output=%s | "
                    "total=%s | "
                    "monthly=%s | "
                    "global=%s"
                ),
                user_id,
                input_tokens,
                output_tokens,
                total_tokens,
                user_usage,
                global_usage,
            )

            return user_usage

        except RedisError as error:
            self._redis_available = False

            self.logger.error(
                (
                    "[QUOTA] Erro Redis ao "
                    "registrar uso | "
                    "type=%s | detail=%s"
                ),
                type(error).__name__,
                error,
            )

            # ====================================================
            # FAIL OPEN
            # ====================================================

            return await self.get_usage(
                user_id
            )

        except Exception as error:
            self.logger.exception(
                (
                    "[QUOTA] Erro inesperado "
                    "ao registrar uso: %s"
                ),
                error,
            )

            return await self.get_usage(
                user_id
            )

    # ============================================================
    # REGISTRAR + STATUS
    # ============================================================

    async def register_usage_and_get_status(
        self,
        user_id: str,
        input_tokens: int = 0,
        output_tokens: int = 0,
    ) -> dict:
        await self.register_usage(
            user_id=user_id,
            input_tokens=input_tokens,
            output_tokens=output_tokens,
        )

        return await self.get_status(
            user_id
        )

    # ============================================================
    # NÍVEL
    # ============================================================

    def _get_usage_level(
        self,
        percentage: float,
    ) -> str:
        if (
            percentage
            >= self.BLOCKED_PERCENTAGE
        ):
            return "blocked"

        if (
            percentage
            >= self.CRITICAL_PERCENTAGE
        ):
            return "critical"

        if (
            percentage
            >= self.WARNING_PERCENTAGE
        ):
            return "warning"

        return "normal"

    # ============================================================
    # MENSAGEM
    # ============================================================

    def _get_usage_message(
        self,
        percentage: float,
    ) -> str:
        if (
            percentage
            >= self.BLOCKED_PERCENTAGE
        ):
            return (
                "Seus créditos Versin acabaram "
                "neste ciclo mensal."
            )

        if (
            percentage
            >= self.CRITICAL_PERCENTAGE
        ):
            return (
                "Seus créditos Versin estão "
                "quase no fim."
            )

        if (
            percentage
            >= self.WARNING_PERCENTAGE
        ):
            return (
                "Você já utilizou 80% ou mais "
                "dos seus créditos Versin."
            )

        return (
            "Uso normal da IA."
        )

    # ============================================================
    # BARRA
    # ============================================================

    def _build_progress_bar(
        self,
        percentage: float,
        size: int = 18,
    ) -> str:
        normalized = min(
            self.BLOCKED_PERCENTAGE,
            max(
                0.0,
                percentage,
            ),
        )

        size = max(
            int(size),
            1,
        )

        filled = round(
            normalized
            / 100
            * size
        )

        filled = max(
            0,
            min(
                filled,
                size,
            ),
        )

        empty = (
            size
            - filled
        )

        return (
            "█" * filled
            + "░" * empty
        )

    # ============================================================
    # STATUS COMPLETO
    # ============================================================

    async def get_status(
        self,
        user_id: str,
    ) -> dict:
        user_id = (
            self._validate_user_id(
                user_id
            )
        )

        # ========================================================
        # BUSCAR USOS
        # ========================================================

        usage = await self.get_usage(
            user_id
        )

        global_usage = (
            await self
            .get_global_daily_usage()
        )

        # ========================================================
        # MENSAL
        # ========================================================

        remaining = max(
            0,
            (
                self.monthly_token_limit
                - usage
            ),
        )

        percentage = (
            self._calculate_percentage(
                usage,
                self.monthly_token_limit,
            )
        )

        rounded_percentage = round(
            percentage,
            1,
        )

        level = (
            self._get_usage_level(
                percentage
            )
        )

        message = (
            self._get_usage_message(
                percentage
            )
        )

        progress_bar = (
            self._build_progress_bar(
                percentage
            )
        )

        # ========================================================
        # CICLO
        # ========================================================

        period = (
            self._get_monthly_period_metadata()
        )

        # ========================================================
        # GLOBAL
        # ========================================================

        global_remaining = max(
            0,
            (
                self.global_daily_token_limit
                - global_usage
            ),
        )

        global_percentage = (
            self._calculate_percentage(
                global_usage,
                self.global_daily_token_limit,
            )
        )

        global_blocked = (
            global_usage
            >= self.global_daily_token_limit
        )

        user_blocked = (
            usage
            >= self.monthly_token_limit
        )

        can_use_ai = (
            not user_blocked
            and not global_blocked
        )

        # ========================================================
        # RETORNO
        # ========================================================

        return {
            # ====================================================
            # USUÁRIO
            # ====================================================

            "used_tokens": usage,

            "remaining_tokens": (
                remaining
            ),

            "limit_tokens": (
                self.monthly_token_limit
            ),

            "usage_percentage": (
                rounded_percentage
            ),

            "progress": round(
                min(
                    1.0,
                    rounded_percentage
                    / 100,
                ),
                4,
            ),

            "level": level,

            "message": message,

            "blocked": (
                user_blocked
            ),

            "can_use_ai": (
                can_use_ai
            ),

            # ====================================================
            # CICLO
            # ====================================================

            "period": (
                period["period"]
            ),

            "provider": (
                period["provider"]
            ),

            "billing_cycle_anchor": (
                period[
                    "billing_cycle_anchor"
                ]
            ),

            "renewal_timezone": (
                period[
                    "renewal_timezone"
                ]
            ),

            "period_start": (
                period[
                    "period_start"
                ]
            ),

            "renews_at": (
                period[
                    "renews_at"
                ]
            ),

            "renews_in_seconds": (
                period[
                    "renews_in_seconds"
                ]
            ),

            "renews_in_hours": (
                period[
                    "renews_in_hours"
                ]
            ),

            "renews_in_days": (
                period[
                    "renews_in_days"
                ]
            ),

            # ====================================================
            # BARRA
            # ====================================================

            "progress_bar": (
                progress_bar
            ),

            "progress_text": (
                f"{progress_bar} "
                f"{rounded_percentage:g}%"
            ),

            # ====================================================
            # REDIS
            # ====================================================

            "redis_available": (
                self._redis_available
            ),

            # ====================================================
            # GLOBAL
            # ====================================================

            "global": {
                "used_tokens": (
                    global_usage
                ),

                "remaining_tokens": (
                    global_remaining
                ),

                "limit_tokens": (
                    self.global_daily_token_limit
                ),

                "usage_percentage": round(
                    global_percentage,
                    1,
                ),

                "progress": round(
                    min(
                        1.0,
                        global_percentage
                        / 100,
                    ),
                    4,
                ),

                "blocked": (
                    global_blocked
                ),
            },
        }

    # ============================================================
    # STATUS GLOBAL
    # ============================================================

    async def get_global_status(
        self,
    ) -> dict:
        usage = (
            await self
            .get_global_daily_usage()
        )

        resets_at = (
            self._get_next_day_start()
        )

        resets_in_seconds = (
            self._seconds_until(
                resets_at
            )
        )

        remaining = max(
            0,
            (
                self.global_daily_token_limit
                - usage
            ),
        )

        percentage = (
            self._calculate_percentage(
                usage,
                self.global_daily_token_limit,
            )
        )

        return {
            "used_tokens": (
                usage
            ),

            "remaining_tokens": (
                remaining
            ),

            "limit_tokens": (
                self.global_daily_token_limit
            ),

            "usage_percentage": round(
                percentage,
                1,
            ),

            "progress": round(
                min(
                    1.0,
                    percentage
                    / 100,
                ),
                4,
            ),

            "blocked": (
                usage
                >=
                self.global_daily_token_limit
            ),

            "period": "daily",

            "reset_timezone": "UTC",

            "resets_at": (
                resets_at.isoformat()
            ),

            "resets_in_seconds": (
                resets_in_seconds
            ),

            "redis_available": (
                self._redis_available
            ),
        }

    # ============================================================
    # FECHAR REDIS
    # ============================================================

    async def close(
        self,
    ) -> None:
        try:
            await self.redis.aclose()

        except RedisError as error:
            self.logger.warning(
                (
                    "[QUOTA] Erro ao fechar "
                    "Redis | type=%s | "
                    "detail=%s"
                ),
                type(error).__name__,
                error,
            )