import logging

import httpx

from core.config import settings


class SupabaseAuthService:
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    DEFAULT_TIMEOUT_SECONDS = 15.0
    DEFAULT_CONNECT_TIMEOUT_SECONDS = 10.0

    MAX_ACCESS_TOKEN_LENGTH = 16_384
    MAX_USER_ID_LENGTH = 128

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        *,
        supabase_url: str | None = None,
        publishable_key: str | None = None,
        timeout_seconds: float = DEFAULT_TIMEOUT_SECONDS,
    ):
        self.logger = logging.getLogger(
            __name__
        )

        # ========================================================
        # SUPABASE URL
        # ========================================================

        self.supabase_url = (
            supabase_url
            or settings.SUPABASE_URL
            or ""
        ).strip().rstrip("/")

        # ========================================================
        # PUBLISHABLE KEY
        # ========================================================

        self.publishable_key = (
            publishable_key
            or settings.SUPABASE_PUBLISHABLE_KEY
            or ""
        ).strip()

        # ========================================================
        # VALIDAÇÕES
        # ========================================================

        if not self.supabase_url:
            raise RuntimeError(
                "SUPABASE_URL não configurada."
            )

        if not self.supabase_url.startswith(
            "https://"
        ):
            raise RuntimeError(
                "SUPABASE_URL deve utilizar HTTPS."
            )

        if not self.publishable_key:
            raise RuntimeError(
                (
                    "SUPABASE_PUBLISHABLE_KEY "
                    "não configurada."
                )
            )

        try:
            timeout_seconds = float(
                timeout_seconds
            )

        except (
            TypeError,
            ValueError,
        ) as error:
            raise ValueError(
                (
                    "timeout_seconds deve ser "
                    "um número válido."
                )
            ) from error

        if timeout_seconds <= 0:
            raise ValueError(
                (
                    "timeout_seconds deve ser "
                    "maior que zero."
                )
            )

        # ========================================================
        # ESTADO
        # ========================================================

        self._closed = False

        # ========================================================
        # CLIENTE HTTP
        # ========================================================

        connect_timeout = min(
            self.DEFAULT_CONNECT_TIMEOUT_SECONDS,
            timeout_seconds,
        )

        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                timeout_seconds,
                connect=connect_timeout,
            ),
            follow_redirects=True,
        )

    # ============================================================
    # GET USER
    # ============================================================
    #
    # Consulta:
    #
    # GET /auth/v1/user
    #
    # Headers:
    #
    # apikey: <publishable_key>
    # Authorization: Bearer <access_token>
    #
    # O Supabase valida o token e retorna o usuário autenticado.
    #
    # ============================================================

    async def get_user(
        self,
        *,
        access_token: str,
    ) -> dict:
        self._ensure_open()

        normalized_token = (
            self._normalize_token(
                access_token
            )
        )

        url = (
            f"{self.supabase_url}"
            "/auth/v1/user"
        )

        try:
            response = await (
                self._client.get(
                    url,
                    headers={
                        "apikey": (
                            self.publishable_key
                        ),

                        "Authorization": (
                            "Bearer "
                            f"{normalized_token}"
                        ),
                    },
                )
            )

        # ========================================================
        # TIMEOUT
        # ========================================================

        except httpx.TimeoutException as error:
            self.logger.warning(
                (
                    "[SUPABASE AUTH] "
                    "Timeout ao validar sessão."
                )
            )

            raise RuntimeError(
                (
                    "Tempo limite excedido "
                    "ao validar a sessão "
                    "no Supabase."
                )
            ) from error

        # ========================================================
        # ERRO DE REDE
        # ========================================================

        except httpx.HTTPError as error:
            self.logger.error(
                (
                    "[SUPABASE AUTH] "
                    "Erro HTTP ao acessar "
                    "Supabase Auth: %s"
                ),
                error,
            )

            raise RuntimeError(
                (
                    "Não foi possível acessar "
                    "o Supabase Auth."
                )
            ) from error

        # ========================================================
        # TOKEN INVÁLIDO / EXPIRADO
        # ========================================================

        if response.status_code in {
            401,
            403,
        }:
            raise PermissionError(
                "Sessão inválida ou expirada."
            )

        # ========================================================
        # OUTROS ERROS
        # ========================================================

        if response.is_error:
            self.logger.error(
                (
                    "[SUPABASE AUTH] "
                    "Resposta inesperada | "
                    "status=%s"
                ),
                response.status_code,
            )

            raise RuntimeError(
                (
                    "Supabase Auth retornou "
                    f"HTTP {response.status_code}."
                )
            )

        # ========================================================
        # JSON
        # ========================================================

        try:
            payload = (
                response.json()
            )

        except ValueError as error:
            raise RuntimeError(
                (
                    "Supabase Auth retornou "
                    "uma resposta inválida."
                )
            ) from error

        if not isinstance(
            payload,
            dict,
        ):
            raise RuntimeError(
                (
                    "Resposta inválida "
                    "do Supabase Auth."
                )
            )

        # ========================================================
        # VALIDAR IDENTIDADE
        # ========================================================

        user_id = (
            self._extract_user_id(
                payload
            )
        )

        if not user_id:
            raise PermissionError(
                (
                    "Usuário autenticado "
                    "não identificado."
                )
            )

        return payload

    # ============================================================
    # GET USER ID
    # ============================================================

    async def get_user_id(
        self,
        *,
        access_token: str,
    ) -> str:
        user = await self.get_user(
            access_token=access_token,
        )

        user_id = (
            self._extract_user_id(
                user
            )
        )

        if not user_id:
            raise PermissionError(
                (
                    "Usuário autenticado "
                    "não identificado."
                )
            )

        return user_id

    # ============================================================
    # VALIDATE TOKEN
    # ============================================================

    async def validate_token(
        self,
        *,
        access_token: str,
    ) -> bool:
        try:
            await self.get_user(
                access_token=access_token,
            )

            return True

        except (
            PermissionError,
            TypeError,
            ValueError,
        ):
            return False

    # ============================================================
    # EXTRAIR USER ID
    # ============================================================

    def _extract_user_id(
        self,
        payload: dict,
    ) -> str:
        raw_user_id = (
            payload.get(
                "id"
            )
        )

        if raw_user_id is None:
            return ""

        user_id = str(
            raw_user_id
        ).strip()

        if not user_id:
            return ""

        if (
            len(user_id)
            >
            self.MAX_USER_ID_LENGTH
        ):
            return ""

        return user_id

    # ============================================================
    # NORMALIZAR TOKEN
    # ============================================================

    def _normalize_token(
        self,
        access_token: str,
    ) -> str:
        # ========================================================
        # VALIDAR TIPO
        # ========================================================

        if not isinstance(
            access_token,
            str,
        ):
            raise PermissionError(
                "Access token inválido."
            )

        normalized_token = (
            access_token.strip()
        )

        # ========================================================
        # ACEITAR "Bearer ..."
        # ========================================================

        if (
            normalized_token
            .lower()
            .startswith(
                "bearer "
            )
        ):
            normalized_token = (
                normalized_token[
                    7:
                ]
                .strip()
            )

        # ========================================================
        # AUSENTE
        # ========================================================

        if not normalized_token:
            raise PermissionError(
                "Access token ausente."
            )

        # ========================================================
        # LIMITE DEFENSIVO
        # ========================================================

        if (
            len(normalized_token)
            >
            self.MAX_ACCESS_TOKEN_LENGTH
        ):
            raise PermissionError(
                "Access token inválido."
            )

        # ========================================================
        # EVITAR TOKEN COM QUEBRA DE LINHA
        # ========================================================

        if (
            "\n" in normalized_token
            or "\r" in normalized_token
        ):
            raise PermissionError(
                "Access token inválido."
            )

        return normalized_token

    # ============================================================
    # ENSURE OPEN
    # ============================================================

    def _ensure_open(
        self,
    ) -> None:
        if self._closed:
            raise RuntimeError(
                (
                    "SupabaseAuthService "
                    "já foi fechado."
                )
            )

    # ============================================================
    # CLOSE
    # ============================================================

    async def close(
        self,
    ) -> None:
        if self._closed:
            return

        self._closed = True

        try:
            await self._client.aclose()

        except Exception as error:
            self.logger.warning(
                (
                    "[SUPABASE AUTH] "
                    "Erro ao fechar "
                    "cliente HTTP: %s"
                ),
                error,
            )

    # ============================================================
    # ASYNC CONTEXT MANAGER
    # ============================================================

    async def __aenter__(
        self,
    ):
        self._ensure_open()

        return self

    async def __aexit__(
        self,
        exc_type,
        exc_value,
        traceback,
    ) -> None:
        await self.close()