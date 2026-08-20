import httpx

from core.config import settings


# ============================================================
# SUPABASE AUTH SERVICE
# ============================================================
#
# Valida o access token recebido do Flutter.
#
# A identidade retornada pelo Supabase é a única fonte aceita
# para descobrir o user_id.
#
# ============================================================


class SupabaseAuthService:
    def __init__(
        self,
        *,
        timeout_seconds: float = 15.0,
    ):
        self.supabase_url = (
            settings
            .SUPABASE_URL
            .strip()
            .rstrip("/")
        )

        self.anon_key = (
            settings
            .SUPABASE_ANON_KEY
            .strip()
        )

        if not self.supabase_url:
            raise RuntimeError(
                "SUPABASE_URL não configurada."
            )

        if not self.anon_key:
            raise RuntimeError(
                "SUPABASE_ANON_KEY não configurada."
            )

        self._client = httpx.AsyncClient(
            timeout=httpx.Timeout(
                timeout_seconds,
                connect=10.0,
            ),
            follow_redirects=True,
        )

        self._closed = False

    # ========================================================
    # GET USER
    # ========================================================

    async def get_user(
        self,
        *,
        access_token: str,
    ) -> dict:
        self._ensure_open()

        normalized_token = (
            access_token
            .strip()
        )

        if not normalized_token:
            raise ValueError(
                "Access token ausente."
            )

        try:
            response = await self._client.get(
                (
                    f"{self.supabase_url}"
                    "/auth/v1/user"
                ),
                headers={
                    "apikey":
                        self.anon_key,

                    "authorization":
                        (
                            "Bearer "
                            f"{normalized_token}"
                        ),
                },
            )

        except httpx.HTTPError as error:
            raise RuntimeError(
                "Não foi possível validar "
                "o usuário no Supabase."
            ) from error

        if response.status_code in (
            401,
            403,
        ):
            raise PermissionError(
                "Sessão inválida ou expirada."
            )

        if response.is_error:
            raise RuntimeError(
                "Supabase Auth retornou "
                f"HTTP {response.status_code}."
            )

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

        user_id = (
            str(
                payload.get(
                    "id",
                    "",
                )
            )
            .strip()
        )

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

        return str(
            user["id"]
        ).strip()

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
    # CONTEXT MANAGER
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