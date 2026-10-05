import logging

import redis.asyncio as redis

from fastapi import HTTPException
from redis.exceptions import RedisError

from core.config import settings


class RateLimiter:
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    DEFAULT_WINDOW_SECONDS = 60

    KEY_PREFIX = "rate_limit:ai"

    # ============================================================
    # SCRIPT REDIS
    # ============================================================
    #
    # Incrementa e adiciona expiração de forma atômica.
    #
    # Isso evita o cenário:
    #
    # INCR funciona
    # ↓
    # aplicação cai
    # ↓
    # EXPIRE nunca é executado
    # ↓
    # chave fica permanente
    #
    # ============================================================

    _RATE_LIMIT_SCRIPT = """
local current = redis.call('INCR', KEYS[1])

if current == 1 then
    redis.call(
        'EXPIRE',
        KEYS[1],
        ARGV[1]
    )
end

local ttl = redis.call(
    'TTL',
    KEYS[1]
)

return {
    current,
    ttl
}
"""

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        requests_per_minute: int | None = None,
        window_seconds: int = DEFAULT_WINDOW_SECONDS,
    ):
        # ========================================================
        # LOGGER
        # ========================================================

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

        self.r = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
        )

        # ========================================================
        # LIMITE
        # ========================================================

        self.limit = (
            requests_per_minute
            if requests_per_minute is not None
            else settings.AI_RATE_LIMIT_PER_MINUTE
        )

        self.window_seconds = (
            window_seconds
        )

        # ========================================================
        # VALIDAÇÕES
        # ========================================================

        if (
            not isinstance(
                self.limit,
                int,
            )
            or self.limit <= 0
        ):
            raise ValueError(
                (
                    "requests_per_minute "
                    "deve ser maior que zero."
                )
            )

        if (
            not isinstance(
                self.window_seconds,
                int,
            )
            or self.window_seconds <= 0
        ):
            raise ValueError(
                (
                    "window_seconds "
                    "deve ser maior que zero."
                )
            )

    # ============================================================
    # NORMALIZAR USER ID
    # ============================================================

    @staticmethod
    def _normalize_user_id(
        user_id: str,
    ) -> str:
        if not isinstance(
            user_id,
            str,
        ):
            raise HTTPException(
                status_code=400,
                detail="Usuário inválido.",
            )

        normalized = (
            user_id.strip()
        )

        if not normalized:
            raise HTTPException(
                status_code=400,
                detail="Usuário inválido.",
            )

        # ========================================================
        # LIMITE DEFENSIVO
        # ========================================================

        if len(normalized) > 128:
            raise HTTPException(
                status_code=400,
                detail="Usuário inválido.",
            )

        return normalized

    # ============================================================
    # CHAVE REDIS
    # ============================================================

    def _get_key(
        self,
        user_id: str,
    ) -> str:
        return (
            f"{self.KEY_PREFIX}:"
            f"{user_id}"
        )

    # ============================================================
    # VERIFICAR RATE LIMIT
    # ============================================================

    async def check_rate_limit(
        self,
        user_id: str,
    ) -> None:
        user_id = (
            self._normalize_user_id(
                user_id
            )
        )

        key = self._get_key(
            user_id
        )

        try:
            # ====================================================
            # INCREMENTAR + EXPIRAR ATOMICAMENTE
            # ====================================================

            result = await self.r.eval(
                self._RATE_LIMIT_SCRIPT,
                1,
                key,
                self.window_seconds,
            )

            # ====================================================
            # NORMALIZAR RESULTADO
            # ====================================================

            current = self._safe_int(
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

            ttl = self._safe_int(
                result[1]
                if (
                    isinstance(
                        result,
                        (list, tuple),
                    )
                    and len(result) > 1
                )
                else self.window_seconds
            )

            # ====================================================
            # DENTRO DO LIMITE
            # ====================================================

            if current <= self.limit:
                return

            # ====================================================
            # BLOQUEADO
            # ====================================================

            retry_after = max(
                ttl,
                1,
            )

            self.logger.warning(
                (
                    "[RATE LIMITER] "
                    "Limite atingido | "
                    "user=%s | "
                    "used=%s | "
                    "limit=%s | "
                    "retry_after=%ss"
                ),
                user_id,
                current,
                self.limit,
                retry_after,
            )

            raise HTTPException(
                status_code=429,
                detail={
                    "message": (
                        "Limite de requisições "
                        "atingido."
                    ),

                    "reason": (
                        "rate_limit"
                    ),

                    "used_requests": (
                        current
                    ),

                    "limit": (
                        self.limit
                    ),

                    "window_seconds": (
                        self.window_seconds
                    ),

                    "retry_after": (
                        retry_after
                    ),
                },
                headers={
                    "Retry-After": str(
                        retry_after
                    ),
                },
            )

        # ========================================================
        # HTTP ESPERADO
        # ========================================================

        except HTTPException:
            raise

        # ========================================================
        # REDIS INDISPONÍVEL
        # ========================================================
        #
        # FAIL OPEN:
        #
        # Se o Redis estiver indisponível, permitimos a chamada
        # para não derrubar completamente o chat.
        #
        # A quota de tokens continua sendo outra camada
        # independente de proteção.
        #
        # ========================================================

        except RedisError as error:
            self.logger.error(
                (
                    "[RATE LIMITER] "
                    "Redis indisponível. "
                    "Rate limit ignorado: %s"
                ),
                error,
            )

    # ============================================================
    # CONSULTAR STATUS
    # ============================================================

    async def get_status(
        self,
        user_id: str,
    ) -> dict:
        user_id = (
            self._normalize_user_id(
                user_id
            )
        )

        key = self._get_key(
            user_id
        )

        try:
            # ====================================================
            # BUSCAR CONTADOR + TTL
            # ====================================================

            async with self.r.pipeline(
                transaction=False
            ) as pipe:
                pipe.get(
                    key
                )

                pipe.ttl(
                    key
                )

                result = await pipe.execute()

            current_raw = (
                result[0]
                if len(result) > 0
                else None
            )

            ttl_raw = (
                result[1]
                if len(result) > 1
                else 0
            )

            # ====================================================
            # NORMALIZAR
            # ====================================================

            current = self._safe_int(
                current_raw
            )

            ttl = self._safe_int(
                ttl_raw
            )

            # ====================================================
            # RESTANTES
            # ====================================================

            remaining = max(
                self.limit - current,
                0,
            )

            # ====================================================
            # IMPORTANTE
            # ====================================================
            #
            # check_rate_limit permite:
            #
            # current <= limit
            #
            # Portanto só consideramos bloqueado quando:
            #
            # current > limit
            #
            # ====================================================

            blocked = (
                current
                >
                self.limit
            )

            return {
                "used_requests": (
                    current
                ),

                "remaining_requests": (
                    remaining
                ),

                "limit": (
                    self.limit
                ),

                "window_seconds": (
                    self.window_seconds
                ),

                "retry_after": (
                    ttl
                    if blocked
                    else 0
                ),

                "blocked": (
                    blocked
                ),
            }

        # ========================================================
        # REDIS INDISPONÍVEL
        # ========================================================

        except RedisError as error:
            self.logger.error(
                (
                    "[RATE LIMITER] "
                    "Erro ao consultar "
                    "status: %s"
                ),
                error,
            )

            # ====================================================
            # FAIL OPEN
            # ====================================================

            return {
                "used_requests": 0,

                "remaining_requests": (
                    self.limit
                ),

                "limit": (
                    self.limit
                ),

                "window_seconds": (
                    self.window_seconds
                ),

                "retry_after": 0,

                "blocked": False,

                "redis_available": False,
            }

    # ============================================================
    # RESET MANUAL
    # ============================================================

    async def reset(
        self,
        user_id: str,
    ) -> None:
        user_id = (
            self._normalize_user_id(
                user_id
            )
        )

        key = self._get_key(
            user_id
        )

        try:
            await self.r.delete(
                key
            )

            self.logger.info(
                (
                    "[RATE LIMITER] "
                    "Limite resetado | "
                    "user=%s"
                ),
                user_id,
            )

        except RedisError as error:
            self.logger.error(
                (
                    "[RATE LIMITER] "
                    "Erro ao resetar "
                    "limite: %s"
                ),
                error,
            )

    # ============================================================
    # CONVERSÃO SEGURA
    # ============================================================

    @staticmethod
    def _safe_int(
        value,
    ) -> int:
        try:
            return max(
                int(
                    value
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
    # FECHAR REDIS
    # ============================================================

    async def close(
        self,
    ) -> None:
        try:
            await self.r.aclose()

        except RedisError as error:
            self.logger.warning(
                (
                    "[RATE LIMITER] "
                    "Erro ao fechar "
                    "Redis: %s"
                ),
                error,
            )