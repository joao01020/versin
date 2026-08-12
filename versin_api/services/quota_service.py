from datetime import datetime, timezone

import redis.asyncio as redis

from core.config import settings


class QuotaService:
    # ============================================================
    # FAIXAS DE USO
    # ============================================================

    WARNING_PERCENTAGE = 70.0
    CRITICAL_PERCENTAGE = 90.0
    BLOCKED_PERCENTAGE = 100.0

    # ============================================================
    # EXPIRAÇÕES
    # ============================================================

    MONTHLY_EXPIRATION_SECONDS = (
        60 * 60 * 24 * 40
    )

    DAILY_EXPIRATION_SECONDS = (
        60 * 60 * 24 * 2
    )

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        monthly_token_limit: int | None = None,
        global_daily_token_limit: int | None = None,
    ):
        if not settings.REDIS_URL:
            raise ValueError(
                "REDIS_URL não configurada no arquivo .env"
            )

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

        if self.monthly_token_limit <= 0:
            raise ValueError(
                "AI_MONTHLY_TOKEN_LIMIT deve ser maior que zero."
            )

        if self.global_daily_token_limit <= 0:
            raise ValueError(
                "AI_GLOBAL_DAILY_TOKEN_LIMIT deve ser maior que zero."
            )

        self.redis = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,

            # ====================================================
            # CONEXÃO REMOTA / UPSTASH
            # ====================================================

            socket_connect_timeout=10,
            socket_timeout=10,
            retry_on_timeout=True,
            health_check_interval=30,
        )

        self._redis_available = True

    # ============================================================
    # TESTAR CONEXÃO REDIS
    # ============================================================

    async def check_connection(
        self,
    ) -> bool:
        try:
            result = await self.redis.ping()

            self._redis_available = bool(
                result
            )

            if self._redis_available:
                print(
                    "[QUOTA] Redis conectado com sucesso."
                )

            return self._redis_available

        except redis.RedisError as error:
            self._redis_available = False

            print(
                (
                    "[QUOTA] Redis indisponível: "
                    f"{type(error).__name__}: "
                    f"{error}"
                )
            )

            return False

        except Exception as error:
            self._redis_available = False

            print(
                (
                    "[QUOTA] Erro inesperado ao testar Redis: "
                    f"{type(error).__name__}: "
                    f"{error}"
                )
            )

            return False

    # ============================================================
    # ESTADO DA CONEXÃO
    # ============================================================

    @property
    def redis_available(
        self,
    ) -> bool:
        return self._redis_available

    # ============================================================
    # RECONEXÃO
    # ============================================================

    async def ensure_connection(
        self,
    ) -> bool:
        if self._redis_available:
            return True

        return await self.check_connection()

    # ============================================================
    # DATA ATUAL UTC
    # ============================================================

    @staticmethod
    def _now() -> datetime:
        return datetime.now(
            timezone.utc
        )

    # ============================================================
    # CHAVE MENSAL DO USUÁRIO
    # ============================================================

    def _get_month_key(
        self,
        user_id: str,
    ) -> str:
        month = self._now().strftime(
            "%Y-%m"
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
        day = self._now().strftime(
            "%Y-%m-%d"
        )

        return (
            f"ai_quota:global:"
            f"{day}"
        )

    # ============================================================
    # VALIDAR USUÁRIO
    # ============================================================

    @staticmethod
    def _validate_user_id(
        user_id: str,
    ) -> str:
        if not isinstance(
            user_id,
            str,
        ):
            raise ValueError(
                "user_id inválido."
            )

        normalized = user_id.strip()

        if not normalized:
            raise ValueError(
                "user_id inválido."
            )

        return normalized

    # ============================================================
    # NORMALIZAR TOKENS
    # ============================================================

    @staticmethod
    def _normalize_tokens(
        tokens: int,
    ) -> int:
        try:
            return max(
                int(tokens),
                0,
            )

        except (
            TypeError,
            ValueError,
        ):
            return 0

    # ============================================================
    # USO MENSAL DO USUÁRIO
    # ============================================================

    async def get_usage(
        self,
        user_id: str,
    ) -> int:
        user_id = self._validate_user_id(
            user_id
        )

        key = self._get_month_key(
            user_id
        )

        try:
            value = await self.redis.get(
                key
            )

            if value is None:
                return 0

            self._redis_available = True

            return max(
                int(value),
                0,
            )

        except redis.RedisError as error:
            self._redis_available = False

            print(
                (
                    "[QUOTA] Erro ao consultar quota mensal: "
                    f"{type(error).__name__}: "
                    f"{error}"
                )
            )

            return 0

    # ============================================================
    # USO GLOBAL DO DIA
    # ============================================================

    async def get_global_daily_usage(
        self,
    ) -> int:
        key = self._get_global_day_key()

        try:
            value = await self.redis.get(
                key
            )

            if value is None:
                return 0

            self._redis_available = True

            return max(
                int(value),
                0,
            )

        except redis.RedisError as error:
            self._redis_available = False

            print(
                (
                    "[QUOTA] Erro ao consultar quota global diária: "
                    f"{type(error).__name__}: "
                    f"{error}"
                )
            )

            return 0

    # ============================================================
    # TOKENS RESTANTES DO USUÁRIO
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
            self.monthly_token_limit
            - usage,
        )

    # ============================================================
    # TOKENS GLOBAIS RESTANTES HOJE
    # ============================================================

    async def get_global_daily_remaining(
        self,
    ) -> int:
        usage = await self.get_global_daily_usage()

        return max(
            0,
            self.global_daily_token_limit
            - usage,
        )

    # ============================================================
    # CALCULAR PERCENTUAL
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
    # PERCENTUAL MENSAL DO USUÁRIO
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
    # PERCENTUAL GLOBAL DO DIA
    # ============================================================

    async def get_global_daily_percentage(
        self,
    ) -> float:
        usage = await self.get_global_daily_usage()

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

        estimated_tokens = self._normalize_tokens(
            estimated_tokens
        )

        projected_usage = (
            usage
            + estimated_tokens
        )

        return (
            projected_usage
            < self.monthly_token_limit
        )

    # ============================================================
    # VERIFICAR LIMITE GLOBAL
    # ============================================================

    async def check_global_limit(
        self,
        estimated_tokens: int = 0,
    ) -> bool:
        usage = await self.get_global_daily_usage()

        estimated_tokens = self._normalize_tokens(
            estimated_tokens
        )

        projected_usage = (
            usage
            + estimated_tokens
        )

        return (
            projected_usage
            < self.global_daily_token_limit
        )

    # ============================================================
    # VERIFICAR SE PODE USAR IA
    # ============================================================

    async def check_limit(
        self,
        user_id: str,
        estimated_tokens: int = 0,
    ) -> bool:
        user_allowed = await self.check_user_limit(
            user_id=user_id,
            estimated_tokens=estimated_tokens,
        )

        if not user_allowed:
            return False

        global_allowed = await self.check_global_limit(
            estimated_tokens=estimated_tokens,
        )

        return global_allowed

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
        usage = await self.get_global_daily_usage()

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
        user_id = self._validate_user_id(
            user_id
        )

        input_tokens = self._normalize_tokens(
            input_tokens
        )

        output_tokens = self._normalize_tokens(
            output_tokens
        )

        total_tokens = (
            input_tokens
            + output_tokens
        )

        if total_tokens == 0:
            return await self.get_usage(
                user_id
            )

        user_key = self._get_month_key(
            user_id
        )

        global_key = self._get_global_day_key()

        try:
            # ====================================================
            # QUOTA MENSAL DO USUÁRIO
            # ====================================================

            user_usage = await self.redis.incrby(
                user_key,
                total_tokens,
            )

            await self.redis.expire(
                user_key,
                self.MONTHLY_EXPIRATION_SECONDS,
            )

            # ====================================================
            # QUOTA GLOBAL DO DIA
            # ====================================================

            global_usage = await self.redis.incrby(
                global_key,
                total_tokens,
            )

            await self.redis.expire(
                global_key,
                self.DAILY_EXPIRATION_SECONDS,
            )

            self._redis_available = True

            print(
                (
                    "[QUOTA] Uso registrado | "
                    f"user={user_id} | "
                    f"input={input_tokens} | "
                    f"output={output_tokens} | "
                    f"total={total_tokens} | "
                    f"monthly={user_usage} | "
                    f"global={global_usage}"
                )
            )

            return int(
                user_usage
            )

        except redis.RedisError as error:
            self._redis_available = False

            print(
                (
                    "[QUOTA] Erro Redis ao registrar uso | "
                    f"type={type(error).__name__} | "
                    f"detail={error}"
                )
            )

            return await self.get_usage(
                user_id
            )

        except Exception as error:
            print(
                (
                    "[QUOTA] Erro inesperado ao registrar uso: "
                    f"{repr(error)}"
                )
            )

            return await self.get_usage(
                user_id
            )

    # ============================================================
    # REGISTRAR E RETORNAR STATUS
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
        if percentage >= self.BLOCKED_PERCENTAGE:
            return "blocked"

        if percentage >= self.CRITICAL_PERCENTAGE:
            return "critical"

        if percentage >= self.WARNING_PERCENTAGE:
            return "warning"

        return "normal"

    # ============================================================
    # MENSAGEM DO USUÁRIO
    # ============================================================

    def _get_usage_message(
        self,
        percentage: float,
    ) -> str:
        if percentage >= self.BLOCKED_PERCENTAGE:
            return (
                "Limite mensal de IA atingido."
            )

        if percentage >= self.CRITICAL_PERCENTAGE:
            return (
                "Seu limite mensal está próximo."
            )

        if percentage >= self.WARNING_PERCENTAGE:
            return (
                "Você já utilizou boa parte "
                "da sua IA este mês."
            )

        return (
            "Uso normal da IA."
        )

    # ============================================================
    # BARRA TEXTUAL
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

        filled = round(
            normalized
            / 100
            * size
        )

        empty = max(
            0,
            size - filled,
        )

        return (
            "█" * filled
            + "░" * empty
        )

    # ============================================================
    # STATUS COMPLETO DO USUÁRIO
    # ============================================================

    async def get_status(
        self,
        user_id: str,
    ) -> dict:
        user_id = self._validate_user_id(
            user_id
        )

        usage = await self.get_usage(
            user_id
        )

        remaining = max(
            0,
            self.monthly_token_limit
            - usage,
        )

        percentage = self._calculate_percentage(
            usage,
            self.monthly_token_limit,
        )

        rounded_percentage = round(
            percentage,
            1,
        )

        level = self._get_usage_level(
            percentage
        )

        message = self._get_usage_message(
            percentage
        )

        progress_bar = self._build_progress_bar(
            percentage
        )

        # ========================================================
        # GLOBAL
        # ========================================================

        global_usage = await self.get_global_daily_usage()

        global_remaining = max(
            0,
            self.global_daily_token_limit
            - global_usage,
        )

        global_percentage = self._calculate_percentage(
            global_usage,
            self.global_daily_token_limit,
        )

        global_blocked = (
            global_usage
            >= self.global_daily_token_limit
        )

        user_blocked = (
            level == "blocked"
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
            # QUOTA DO USUÁRIO
            # ====================================================

            "used_tokens":
                usage,

            "remaining_tokens":
                remaining,

            "limit_tokens":
                self.monthly_token_limit,

            "usage_percentage":
                rounded_percentage,

            "progress":
                round(
                    rounded_percentage / 100,
                    4,
                ),

            "level":
                level,

            "message":
                message,

            "blocked":
                user_blocked,

            "can_use_ai":
                can_use_ai,

            # ====================================================
            # BARRA
            # ====================================================

            "progress_bar":
                progress_bar,

            "progress_text":
                (
                    f"{progress_bar} "
                    f"{rounded_percentage:g}%"
                ),

            # ====================================================
            # REDIS
            # ====================================================

            "redis_available":
                self._redis_available,

            # ====================================================
            # QUOTA GLOBAL
            # ====================================================

            "global": {
                "used_tokens":
                    global_usage,

                "remaining_tokens":
                    global_remaining,

                "limit_tokens":
                    self.global_daily_token_limit,

                "usage_percentage":
                    round(
                        global_percentage,
                        1,
                    ),

                "progress":
                    round(
                        min(
                            1.0,
                            global_percentage / 100,
                        ),
                        4,
                    ),

                "blocked":
                    global_blocked,
            },
        }

    # ============================================================
    # STATUS GLOBAL
    # ============================================================

    async def get_global_status(
        self,
    ) -> dict:
        usage = await self.get_global_daily_usage()

        remaining = max(
            0,
            self.global_daily_token_limit
            - usage,
        )

        percentage = self._calculate_percentage(
            usage,
            self.global_daily_token_limit,
        )

        return {
            "used_tokens":
                usage,

            "remaining_tokens":
                remaining,

            "limit_tokens":
                self.global_daily_token_limit,

            "usage_percentage":
                round(
                    percentage,
                    1,
                ),

            "progress":
                round(
                    min(
                        1.0,
                        percentage / 100,
                    ),
                    4,
                ),

            "blocked":
                usage
                >= self.global_daily_token_limit,
        }

    # ============================================================
    # FECHAR REDIS
    # ============================================================

    async def close(
        self,
    ) -> None:
        try:
            await self.redis.aclose()

        except redis.RedisError as error:
            print(
                (
                    "[QUOTA] Erro ao fechar Redis: "
                    f"{type(error).__name__}: "
                    f"{error}"
                )
            )