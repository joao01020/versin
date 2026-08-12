import redis.asyncio as redis
from fastapi import HTTPException

from core.config import settings


class RateLimiter:
    # ============================================================
    # CONFIGURAÇÃO PADRÃO
    # ============================================================

    DEFAULT_WINDOW_SECONDS = 60

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        requests_per_minute: int | None = None,
        window_seconds: int = DEFAULT_WINDOW_SECONDS,
    ):
        # ========================================================
        # REDIS
        # ========================================================

        if not settings.REDIS_URL:
            raise ValueError(
                "REDIS_URL não configurada no arquivo .env"
            )

        self.r = redis.from_url(
            settings.REDIS_URL,
            decode_responses=True,
        )

        # ========================================================
        # LIMITE
        # ========================================================
        #
        # Se requests_per_minute for passado manualmente,
        # ele prevalece.
        #
        # Caso contrário, usamos:
        #
        # settings.AI_RATE_LIMIT_PER_MINUTE
        #
        # que vem do .env.
        #
        # ========================================================

        self.limit = (
            requests_per_minute
            if requests_per_minute is not None
            else settings.AI_RATE_LIMIT_PER_MINUTE
        )

        self.window_seconds = window_seconds

        # ========================================================
        # VALIDAÇÕES
        # ========================================================

        if self.limit <= 0:
            raise ValueError(
                "requests_per_minute deve ser maior que zero."
            )

        if self.window_seconds <= 0:
            raise ValueError(
                "window_seconds deve ser maior que zero."
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

        normalized = user_id.strip()

        if not normalized:
            raise HTTPException(
                status_code=400,
                detail="Usuário inválido.",
            )

        return normalized

    # ============================================================
    # CHAVE DO REDIS
    # ============================================================

    def _get_key(
        self,
        user_id: str,
    ) -> str:
        return (
            f"rate_limit:"
            f"ai:"
            f"{user_id}"
        )

    # ============================================================
    # VERIFICAR RATE LIMIT
    # ============================================================

    async def check_rate_limit(
        self,
        user_id: str,
    ) -> None:
        user_id = self._normalize_user_id(
            user_id
        )

        key = self._get_key(
            user_id
        )

        try:
            # ====================================================
            # INCREMENTAR CONTADOR
            # ====================================================

            current = await self.r.incr(
                key
            )

            # ====================================================
            # PRIMEIRA REQUISIÇÃO DA JANELA
            # ====================================================

            if current == 1:
                await self.r.expire(
                    key,
                    self.window_seconds,
                )

            # ====================================================
            # AINDA ESTÁ DENTRO DO LIMITE
            # ====================================================

            if current <= self.limit:
                return

            # ====================================================
            # LIMITE ATINGIDO
            # ====================================================

            ttl = await self.r.ttl(
                key
            )

            retry_after = max(
                int(
                    ttl
                ),
                1,
            )

            raise HTTPException(
                status_code=429,
                detail={
                    "message":
                        "Limite de requisições atingido.",

                    "limit":
                        self.limit,

                    "window_seconds":
                        self.window_seconds,

                    "retry_after":
                        retry_after,
                },
                headers={
                    "Retry-After":
                        str(
                            retry_after
                        ),
                },
            )

        # ========================================================
        # ERRO HTTP ESPERADO
        # ========================================================

        except HTTPException:
            raise

        # ========================================================
        # REDIS INDISPONÍVEL
        # ========================================================
        #
        # FAIL OPEN:
        #
        # se o Redis cair, não derrubamos a IA junto.
        #
        # ========================================================

        except redis.RedisError as error:
            print(
                (
                    "[RATE LIMITER] "
                    "Redis indisponível: "
                    f"{error}"
                )
            )

    # ============================================================
    # CONSULTAR STATUS
    # ============================================================
    #
    # Útil futuramente para debug ou painel administrativo.
    #
    # ============================================================

    async def get_status(
        self,
        user_id: str,
    ) -> dict:
        user_id = self._normalize_user_id(
            user_id
        )

        key = self._get_key(
            user_id
        )

        try:
            current_raw = await self.r.get(
                key
            )

            ttl = await self.r.ttl(
                key
            )

            current = (
                int(
                    current_raw
                )
                if current_raw is not None
                else 0
            )

            remaining = max(
                0,
                self.limit
                - current,
            )

            return {
                "used_requests":
                    current,

                "remaining_requests":
                    remaining,

                "limit":
                    self.limit,

                "window_seconds":
                    self.window_seconds,

                "retry_after":
                    max(
                        ttl,
                        0,
                    ),

                "blocked":
                    current
                    >= self.limit,
            }

        except redis.RedisError as error:
            print(
                (
                    "[RATE LIMITER] "
                    "Erro ao consultar status: "
                    f"{error}"
                )
            )

            return {
                "used_requests":
                    0,

                "remaining_requests":
                    self.limit,

                "limit":
                    self.limit,

                "window_seconds":
                    self.window_seconds,

                "retry_after":
                    0,

                "blocked":
                    False,
            }

    # ============================================================
    # RESET MANUAL
    # ============================================================
    #
    # Útil para desenvolvimento/admin.
    #
    # Não precisa ser exposto diretamente para usuários.
    #
    # ============================================================

    async def reset(
        self,
        user_id: str,
    ) -> None:
        user_id = self._normalize_user_id(
            user_id
        )

        key = self._get_key(
            user_id
        )

        try:
            await self.r.delete(
                key
            )

        except redis.RedisError as error:
            print(
                (
                    "[RATE LIMITER] "
                    "Erro ao resetar limite: "
                    f"{error}"
                )
            )

    # ============================================================
    # FECHAR REDIS
    # ============================================================

    async def close(
        self,
    ) -> None:
        try:
            await self.r.aclose()

        except redis.RedisError as error:
            print(
                (
                    "[RATE LIMITER] "
                    "Erro ao fechar Redis: "
                    f"{error}"
                )
            )