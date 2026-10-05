import os

from dotenv import load_dotenv


# ================================================================
# CARREGAR .ENV
# ================================================================

load_dotenv()


# ================================================================
# HELPERS
# ================================================================


def _get_str(
    name: str,
    default: str = "",
) -> str:
    return (
        os.getenv(
            name,
            default,
        )
        or ""
    ).strip()


def _get_int(
    name: str,
    default: int,
) -> int:
    raw_value = _get_str(
        name,
        str(default),
    )

    try:
        return int(
            raw_value
        )

    except (
        TypeError,
        ValueError,
    ) as error:
        raise ValueError(
            (
                f"{name} deve ser "
                "um número inteiro."
            )
        ) from error


# ================================================================
# SETTINGS
# ================================================================


class Settings:
    # ============================================================
    # PROJETO
    # ============================================================

    PROJECT_NAME: str = _get_str(
        "PROJECT_NAME",
        "Versin AI Pro",
    )

    PORT: int = _get_int(
        "PORT",
        8000,
    )

    # ============================================================
    # GROQ
    # ============================================================

    GROQ_API_KEY: str = _get_str(
        "GROQ_API_KEY",
    )

    GROQ_MODEL: str = _get_str(
        "GROQ_MODEL",
        "openai/gpt-oss-20b",
    )

    # ============================================================
    # IA - GERAÇÃO
    # ============================================================
    #
    # Configurações utilizadas pelo AIService / ChatService.
    #
    # Mantemos tudo aqui para que seja possível ajustar no Render
    # sem precisar alterar o código-fonte.
    #
    # ============================================================

    AI_MAX_COMPLETION_TOKENS: int = _get_int(
        "AI_MAX_COMPLETION_TOKENS",
        2048,
    )

    AI_REASONING_EFFORT: str = _get_str(
        "AI_REASONING_EFFORT",
        "low",
    ).lower()

    # ============================================================
    # IA - RETRY DE RESPOSTA VAZIA
    # ============================================================

    AI_EMPTY_RETRY_MULTIPLIER: int = _get_int(
        "AI_EMPTY_RETRY_MULTIPLIER",
        2,
    )

    AI_EMPTY_RETRY_MIN_TOKENS: int = _get_int(
        "AI_EMPTY_RETRY_MIN_TOKENS",
        4096,
    )

    AI_EMPTY_RETRY_MAX_TOKENS: int = _get_int(
        "AI_EMPTY_RETRY_MAX_TOKENS",
        8192,
    )

    # ============================================================
    # REDIS
    # ============================================================

    REDIS_URL: str = _get_str(
        "REDIS_URL",
    )

    # ============================================================
    # SUPABASE
    # ============================================================
    #
    # SUPABASE_URL:
    #
    # URL pública do projeto Supabase.
    #
    # Exemplo:
    #
    # https://xxxxxxxx.supabase.co
    #
    #
    # SUPABASE_PUBLISHABLE_KEY:
    #
    # Publishable Key do projeto.
    #
    # Nunca utilizar aqui:
    #
    # - service_role;
    # - secret key administrativa.
    #
    # A identidade do usuário continua vindo pelo access token
    # enviado pelo aplicativo.
    #
    # ============================================================

    SUPABASE_URL: str = (
        _get_str(
            "SUPABASE_URL",
        )
        .rstrip("/")
    )

    SUPABASE_PUBLISHABLE_KEY: str = _get_str(
        "SUPABASE_PUBLISHABLE_KEY",
    )

    # ============================================================
    # PROJECT STORAGE
    # ============================================================
    #
    # Endpoint privado utilizado pela Versin API para conversar
    # com o Cloudflare Worker responsável pelos arquivos.
    #
    # Flutter
    #   ↓
    # Versin API
    #   ↓
    # Cloudflare Worker
    #   ↓
    # R2
    #
    # O segredo nunca deve ser enviado ao Flutter.
    #
    # ============================================================

    PROJECT_STORAGE_WORKER_URL: str = (
        _get_str(
            "PROJECT_STORAGE_WORKER_URL",
        )
        .rstrip("/")
    )

    VERSIN_API_SECRET: str = _get_str(
        "VERSIN_API_SECRET",
    )

    # ============================================================
    # QUOTA MENSAL POR USUÁRIO
    # ============================================================

    AI_MONTHLY_TOKEN_LIMIT: int = _get_int(
        "AI_MONTHLY_TOKEN_LIMIT",
        50_000,
    )

    # ============================================================
    # LIMITE GLOBAL DIÁRIO DA IA
    # ============================================================

    AI_GLOBAL_DAILY_TOKEN_LIMIT: int = _get_int(
        "AI_GLOBAL_DAILY_TOKEN_LIMIT",
        450_000,
    )

    # ============================================================
    # RATE LIMIT POR USUÁRIO
    # ============================================================

    AI_RATE_LIMIT_PER_MINUTE: int = _get_int(
        "AI_RATE_LIMIT_PER_MINUTE",
        5,
    )

    # ============================================================
    # TAMANHO MÁXIMO DA ENTRADA
    # ============================================================

    AI_MAX_INPUT_LENGTH: int = _get_int(
        "AI_MAX_INPUT_LENGTH",
        12_000,
    )

    # ============================================================
    # VALIDAÇÕES
    # ============================================================

    @classmethod
    def validate(
        cls,
    ) -> None:
        # ========================================================
        # PROJETO
        # ========================================================

        if not cls.PROJECT_NAME:
            raise ValueError(
                "PROJECT_NAME não configurado."
            )

        if cls.PORT <= 0:
            raise ValueError(
                "PORT deve ser maior que zero."
            )

        # ========================================================
        # GROQ
        # ========================================================

        if not cls.GROQ_API_KEY:
            raise ValueError(
                "GROQ_API_KEY não configurada."
            )

        if not cls.GROQ_MODEL:
            raise ValueError(
                "GROQ_MODEL não configurado."
            )

        # ========================================================
        # IA - COMPLETION
        # ========================================================

        if (
            cls.AI_MAX_COMPLETION_TOKENS
            <= 0
        ):
            raise ValueError(
                (
                    "AI_MAX_COMPLETION_TOKENS "
                    "deve ser maior que zero."
                )
            )

        # ========================================================
        # IA - REASONING
        # ========================================================

        allowed_reasoning_efforts = {
            "low",
            "medium",
            "high",
        }

        if (
            cls.AI_REASONING_EFFORT
            not in allowed_reasoning_efforts
        ):
            raise ValueError(
                (
                    "AI_REASONING_EFFORT deve ser "
                    "'low', 'medium' ou 'high'."
                )
            )

        # ========================================================
        # IA - RETRY
        # ========================================================

        if (
            cls.AI_EMPTY_RETRY_MULTIPLIER
            <= 0
        ):
            raise ValueError(
                (
                    "AI_EMPTY_RETRY_MULTIPLIER "
                    "deve ser maior que zero."
                )
            )

        if (
            cls.AI_EMPTY_RETRY_MIN_TOKENS
            <= 0
        ):
            raise ValueError(
                (
                    "AI_EMPTY_RETRY_MIN_TOKENS "
                    "deve ser maior que zero."
                )
            )

        if (
            cls.AI_EMPTY_RETRY_MAX_TOKENS
            <= 0
        ):
            raise ValueError(
                (
                    "AI_EMPTY_RETRY_MAX_TOKENS "
                    "deve ser maior que zero."
                )
            )

        if (
            cls.AI_EMPTY_RETRY_MAX_TOKENS
            <
            cls.AI_EMPTY_RETRY_MIN_TOKENS
        ):
            raise ValueError(
                (
                    "AI_EMPTY_RETRY_MAX_TOKENS "
                    "não pode ser menor que "
                    "AI_EMPTY_RETRY_MIN_TOKENS."
                )
            )

        # ========================================================
        # REDIS
        # ========================================================

        if not cls.REDIS_URL:
            raise ValueError(
                "REDIS_URL não configurada."
            )

        # ========================================================
        # SUPABASE
        # ========================================================

        if not cls.SUPABASE_URL:
            raise ValueError(
                "SUPABASE_URL não configurada."
            )

        if not (
            cls.SUPABASE_URL.startswith(
                "https://"
            )
        ):
            raise ValueError(
                (
                    "SUPABASE_URL deve "
                    "utilizar HTTPS."
                )
            )

        if not (
            cls.SUPABASE_PUBLISHABLE_KEY
        ):
            raise ValueError(
                (
                    "SUPABASE_PUBLISHABLE_KEY "
                    "não configurada."
                )
            )

        # ========================================================
        # PROJECT STORAGE
        # ========================================================

        if not (
            cls.PROJECT_STORAGE_WORKER_URL
        ):
            raise ValueError(
                (
                    "PROJECT_STORAGE_WORKER_URL "
                    "não configurada."
                )
            )

        if not (
            cls.PROJECT_STORAGE_WORKER_URL
            .startswith(
                "https://"
            )
        ):
            raise ValueError(
                (
                    "PROJECT_STORAGE_WORKER_URL "
                    "deve utilizar HTTPS."
                )
            )

        if not cls.VERSIN_API_SECRET:
            raise ValueError(
                (
                    "VERSIN_API_SECRET "
                    "não configurada."
                )
            )

        if (
            len(
                cls.VERSIN_API_SECRET
            )
            < 32
        ):
            raise ValueError(
                (
                    "VERSIN_API_SECRET deve "
                    "possuir pelo menos "
                    "32 caracteres."
                )
            )

        # ========================================================
        # AI QUOTA
        # ========================================================

        if (
            cls.AI_MONTHLY_TOKEN_LIMIT
            <= 0
        ):
            raise ValueError(
                (
                    "AI_MONTHLY_TOKEN_LIMIT "
                    "deve ser maior que zero."
                )
            )

        if (
            cls.AI_GLOBAL_DAILY_TOKEN_LIMIT
            <= 0
        ):
            raise ValueError(
                (
                    "AI_GLOBAL_DAILY_TOKEN_LIMIT "
                    "deve ser maior que zero."
                )
            )

        # ========================================================
        # RATE LIMIT
        # ========================================================

        if (
            cls.AI_RATE_LIMIT_PER_MINUTE
            <= 0
        ):
            raise ValueError(
                (
                    "AI_RATE_LIMIT_PER_MINUTE "
                    "deve ser maior que zero."
                )
            )

        # ========================================================
        # INPUT
        # ========================================================

        if (
            cls.AI_MAX_INPUT_LENGTH
            <= 0
        ):
            raise ValueError(
                (
                    "AI_MAX_INPUT_LENGTH "
                    "deve ser maior que zero."
                )
            )


# ================================================================
# INSTÂNCIA GLOBAL
# ================================================================

settings = Settings()