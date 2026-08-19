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
    )

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
    )

   GROQ_MODEL: str = (
    "openai/gpt-oss-20b"
)

    # ============================================================
    # REDIS
    # ============================================================

    REDIS_URL: str = os.getenv(
        "REDIS_URL",
        "",
    )

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
        if not cls.GROQ_API_KEY:
            raise ValueError(
                "GROQ_API_KEY não configurada no .env"
            )

        if not cls.REDIS_URL:
            raise ValueError(
                "REDIS_URL não configurada no .env"
            )

        if cls.AI_MONTHLY_TOKEN_LIMIT <= 0:
            raise ValueError(
                "AI_MONTHLY_TOKEN_LIMIT deve ser maior que zero."
            )

        if cls.AI_GLOBAL_DAILY_TOKEN_LIMIT <= 0:
            raise ValueError(
                "AI_GLOBAL_DAILY_TOKEN_LIMIT deve ser maior que zero."
            )

        if cls.AI_RATE_LIMIT_PER_MINUTE <= 0:
            raise ValueError(
                "AI_RATE_LIMIT_PER_MINUTE deve ser maior que zero."
            )

        if cls.AI_MAX_INPUT_LENGTH <= 0:
            raise ValueError(
                "AI_MAX_INPUT_LENGTH deve ser maior que zero."
            )


settings = Settings()