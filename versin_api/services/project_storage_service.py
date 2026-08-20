import httpx

from core.config import settings


# ============================================================
# SUPABASE AUTH SERVICE
# ============================================================
#
# Responsável por validar no Supabase o access token recebido
# pela Versin API.
#
# Fluxo:
#
# Flutter
#   ↓
# Authorization: Bearer <access_token>
#   ↓
# Versin API
#   ↓
# Supabase Auth
#   ↓
# usuário autenticado
#
# IMPORTANTE:
#
# - não confia em user_id enviado pelo Flutter;
# - o user_id verdadeiro vem do access token;
# - não utiliza service_role;
# - não utiliza secret key administrativa;
# - utiliza somente a Publishable Key do projeto;
#
# ============================================================


class SupabaseAuthService:
    # ========================================================
    # CONSTRUCTOR
    # ========================================================

    def __init__(
        self,
        *,
        supabase_url: str | None = None,
        publishable_key: str | None = None,
        timeout_seconds: float = 15.0,
    ):
        self.supabase_url = (
            supabase_url
            or settings.SUPABASE_URL
        ).strip().rstrip("/")

        self.publishable_key = (
            publishable_key
            or settings.SUPABASE_PUBLISHABLE_KEY
        ).strip()

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
                "SUPABASE_PUBLISHABLE_KEY não configurada."
            )

        if timeout_seconds <= 0:
            raise ValueError(
                "timeout_seconds deve ser maior que zero."
            )

        self._closed = False

        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                timeout_seconds,
                connect=10.0,
            ),
            follow_redirects=True,
        )

    # ========================================================
    # GET USER
    # ========================================================
    #
    # Consulta:
    #
    # GET /auth/v1/user
    #
    # O Supabase valida o access token e devolve o usuário.
    #
    # ========================================================

    async def get_user(
        self,
        *,
        access_token: str,
    ) -> dict:
        self._ensure_open()

        normalized_token = self._normalize_token(
            access_token
        )

        try:
            response = await self._client.get(
                (
                    f"{self.supabase_url}"
                    "/auth/v1/user"
                ),
                headers={
                    "apikey":
                        self.publishable_key,

                    "authorization":
                        (
                            "Bearer "
                            f"{normalized_token}"
                        ),
                },
            )

        except httpx.TimeoutException as error:
            raise RuntimeError(
                "Tempo limite excedido ao validar "
                "a sessão no Supabase."
            ) from error

        except httpx.HTTPError as error:
            raise RuntimeError(
                "Não foi possível acessar "
                "o Supabase Auth."
            ) from error

        # ====================================================
        # TOKEN INVÁLIDO
        # ====================================================

        if response.status_code in (
            401,
            403,
        ):
            raise PermissionError(
                "Sessão inválida ou expirada."
            )

        # ====================================================
        # OUTRO ERRO
        # ====================================================

        if response.is_error:
            raise RuntimeError(
                "Supabase Auth retornou "
                f"HTTP {response.status_code}."
            )

        # ====================================================
        # JSON
        # ====================================================

        try:
            payload = response.json()

        except ValueError as error:
            raise RuntimeError(
                "Supabase Auth retornou "
                "uma resposta inválida."
            ) from error

        if not isinstance(
            payload,
            dict,
        ):
            raise RuntimeError(
                "Resposta inválida do Supabase Auth."
            )

        # ====================================================
        # VALIDAR IDENTIDADE
        # ====================================================

        user_id = str(
            payload.get(
                "id",
                "",
            )
        ).strip()

        if not user_id:
            raise PermissionError(
                "Usuário autenticado não identificado."
            )

        return payload

    # ========================================================
    # GET USER ID
    # ========================================================

    async def get_user_id(
        self,
        *,
        access_token: str,
    ) -> str:
        user = await self.get_user(
            access_token=
                access_token,
        )

        user_id = str(
            user.get(
                "id",
                "",
            )
        ).strip()

        if not user_id:
            raise PermissionError(
                "Usuário autenticado não identificado."
            )

        return user_id

    # ========================================================
    # VALIDATE TOKEN
    # ========================================================
    #
    # Retorna True somente quando o token representa
    # uma sessão válida.
    #
    # ========================================================

    async def validate_token(
        self,
        *,
        access_token: str,
    ) -> bool:
        try:
            await self.get_user(
                access_token=
                    access_token,
            )

            return True

        except PermissionError:
            return False

    # ========================================================
    # NORMALIZE TOKEN
    # ========================================================

    def _normalize_token(
        self,
        access_token: str,
    ) -> str:
        normalized_token = (
            access_token
            .strip()
        )

        # ====================================================
        # Aceita também:
        #
        # Bearer eyJ...
        #
        # Isso deixa o serviço mais resistente caso futuramente
        # ele seja chamado diretamente com o header.
        # ====================================================

        if normalized_token.lower().startswith(
            "bearer "
        ):
            normalized_token = (
                normalized_token[7:]
                .strip()
            )

        if not normalized_token:
            raise PermissionError(
                "Access token ausente."
            )

        # ====================================================
        # Proteção básica contra entrada absurda.
        # ====================================================

        if len(
            normalized_token
        ) > 16384:
            raise PermissionError(
                "Access token inválido."
            )

        return normalized_token

    # ========================================================
    # ENSURE OPEN
    # ========================================================

    def _ensure_open(
        self,
    ) -> None:
        if self._closed:
            raise RuntimeError(
                "SupabaseAuthService já foi fechado."
            )

    # ========================================================
    # CLOSE
    # ========================================================

    async def close(
        self,
    ) -> None:
        if self._closed:
            return

        self._closed = True

        await self._client.aclose()

    # ========================================================
    # ASYNC CONTEXT MANAGER
    # ========================================================

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