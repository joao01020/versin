import os

from dotenv import load_dotenv


load_dotenv()


class Settings:
    # ============================================================
    # PROJETO
    # ============================================================

    PROJECT_NAME: str = os.getenv(
        "PROJECT_NAME",
        "Versin AI Pro",
    ).strip()

    PORT: int = int(
        os.getenv(
            "PORT",
            "8000",
        )
    )

    # ============================================================
    # GROQ
    # ============================================================

    GROQ_API_KEY: str = os.getenv(
        "GROQ_API_KEY",
        "",
    ).strip()

    GROQ_MODEL: str = os.getenv(
        "GROQ_MODEL",
        "openai/gpt-oss-20b",
    ).strip()

    # ============================================================
    # REDIS
    # ============================================================

    REDIS_URL: str = os.getenv(
        "REDIS_URL",
        "",
    ).strip()

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
    # Ela será utilizada pela Versin API para conversar com
    # endpoints públicos/autenticados do Supabase.
    #
    # NÃO utilizar aqui:
    #
    # - service_role;
    # - secret key administrativa.
    #
    # A identidade real do usuário continuará vindo do
    # access token enviado pelo Flutter.
    #
    # ============================================================

    SUPABASE_URL: str = os.getenv(
        "SUPABASE_URL",
        "",
    ).strip().rstrip("/")

    SUPABASE_PUBLISHABLE_KEY: str = os.getenv(
        "SUPABASE_PUBLISHABLE_KEY",
        "",
    ).strip()

    # ============================================================
    # PROJECT STORAGE
    # ============================================================
    #
    # Endpoint privado utilizado pela Versin API para conversar
    # com o Cloudflare Worker responsável pelos arquivos das
    # entregas dos projetos.
    #
    # Fluxo:
    #
    # Flutter
    #   ↓
    # Versin API
    #   ↓
    # Cloudflare Worker
    #   ↓
    # R2
    #
    # O segredo NUNCA deve ser enviado para o Flutter.
    #
    # ============================================================

    PROJECT_STORAGE_WORKER_URL: str = os.getenv(
        "PROJECT_STORAGE_WORKER_URL",
        "",
    ).strip().rstrip("/")

    VERSIN_API_SECRET: str = os.getenv(
        "VERSIN_API_SECRET",
        "",
    ).strip()

    # ============================================================
    # QUOTA MENSAL POR USUÁRIO
    # ============================================================

    AI_MONTHLY_TOKEN_LIMIT: int = int(
        os.getenv(
            "AI_MONTHLY_TOKEN_LIMIT",
            "50000",
        )
    )

    # ============================================================
    # LIMITE GLOBAL DIÁRIO DA IA
    # ============================================================

    AI_GLOBAL_DAILY_TOKEN_LIMIT: int = int(
        os.getenv(
            "AI_GLOBAL_DAILY_TOKEN_LIMIT",
            "450000",
        )
    )

    # ============================================================
    # RATE LIMIT POR USUÁRIO
    # ============================================================

    AI_RATE_LIMIT_PER_MINUTE: int = int(
        os.getenv(
            "AI_RATE_LIMIT_PER_MINUTE",
            "5",
        )
    )

    # ============================================================
    # TAMANHO MÁXIMO DA ENTRADA
    # ============================================================

    AI_MAX_INPUT_LENGTH: int = int(
        os.getenv(
            "AI_MAX_INPUT_LENGTH",
            "12000",
        )
    )

    # ============================================================
    # VALIDAÇÕES
    # ============================================================

    @classmethod
    def validate(cls) -> None:
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

        if not cls.SUPABASE_URL.startswith(
            "https://"
        ):
            raise ValueError(
                "SUPABASE_URL deve utilizar HTTPS."
            )

        if not cls.SUPABASE_PUBLISHABLE_KEY:
            raise ValueError(
                "SUPABASE_PUBLISHABLE_KEY não configurada."
            )

        # ========================================================
        # PROJECT STORAGE
        # ========================================================

        if not cls.PROJECT_STORAGE_WORKER_URL:
            raise ValueError(
                "PROJECT_STORAGE_WORKER_URL não configurada."
            )

        if not (
            cls.PROJECT_STORAGE_WORKER_URL.startswith(
                "https://"
            )
        ):
            raise ValueError(
                "PROJECT_STORAGE_WORKER_URL deve utilizar HTTPS."
            )

        if not cls.VERSIN_API_SECRET:
            raise ValueError(
                "VERSIN_API_SECRET não configurada."
            )

        if len(
            cls.VERSIN_API_SECRET
        ) < 32:
            raise ValueError(
                "VERSIN_API_SECRET deve possuir pelo menos "
                "32 caracteres."
            )

        # ========================================================
        # AI QUOTA
        # ========================================================

        if cls.AI_MONTHLY_TOKEN_LIMIT <= 0:
            raise ValueError(
                "AI_MONTHLY_TOKEN_LIMIT deve ser maior que zero."
            )

        if cls.AI_GLOBAL_DAILY_TOKEN_LIMIT <= 0:
            raise ValueError(
                "AI_GLOBAL_DAILY_TOKEN_LIMIT deve ser maior que zero."
            )

        # ========================================================
        # RATE LIMIT
        # ========================================================

        if cls.AI_RATE_LIMIT_PER_MINUTE <= 0:
            raise ValueError(
                "AI_RATE_LIMIT_PER_MINUTE deve ser maior que zero."
            )

        # ========================================================
        # INPUT
        # ========================================================

        if cls.AI_MAX_INPUT_LENGTH <= 0:
            raise ValueError(
                "AI_MAX_INPUT_LENGTH deve ser maior que zero."
            )


settings = Settings()