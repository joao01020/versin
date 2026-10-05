from contextlib import asynccontextmanager
from pathlib import Path

from dotenv import load_dotenv
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware


# ============================================================
# .ENV
# ============================================================
#
# Estrutura esperada:
#
# versin/
# ├── .env
# └── versin_api/
#     └── main.py
#
# Portanto, o .env está um nível acima de versin_api.
#
# ============================================================

BASE_DIR = Path(
    __file__
).resolve().parent

PROJECT_DIR = (
    BASE_DIR.parent
)

ENV_FILE = (
    PROJECT_DIR / ".env"
)

load_dotenv(
    dotenv_path=ENV_FILE
)


# ============================================================
# IMPORTS DO PROJETO
# ============================================================

from core.config import settings
from routes.chat_route import router as chat_router
from services.chat_service import ChatService


# ============================================================
# CHAT SERVICE GLOBAL
# ============================================================
#
# Uma única instância durante toda a vida da aplicação.
#
# O ChatService orquestra:
#
# - RateLimiter
# - QuotaService
# - SafetyService
# - PromptEngine
# - AIService
#
# ============================================================

chat_service = ChatService()


# ============================================================
# LIFESPAN
# ============================================================

@asynccontextmanager
async def lifespan(
    app: FastAPI,
):
    # ========================================================
    # STARTUP
    # ========================================================

    print()
    print(
        "=============================================="
    )

    print(
        f"[VERSIN] {settings.PROJECT_NAME}"
    )

    print(
        "[VERSIN] Backend iniciado."
    )

    print(
        f"[VERSIN] Modelo: {settings.GROQ_MODEL}"
    )

    print(
        (
            "[VERSIN] Quota mensal por usuário: "
            f"{settings.AI_MONTHLY_TOKEN_LIMIT} tokens"
        )
    )

    print(
        (
            "[VERSIN] Limite global diário: "
            f"{settings.AI_GLOBAL_DAILY_TOKEN_LIMIT} tokens"
        )
    )

    print(
        (
            "[VERSIN] Rate limit: "
            f"{settings.AI_RATE_LIMIT_PER_MINUTE}/min"
        )
    )

    print(
        (
            "[VERSIN] Entrada máxima: "
            f"{settings.AI_MAX_INPUT_LENGTH} caracteres"
        )
    )

    print(
        f"[VERSIN] ENV: {ENV_FILE}"
    )

    print(
        "=============================================="
    )

    print()

    # ========================================================
    # TESTAR REDIS
    # ========================================================

    print(
        "[VERSIN] Testando conexão com Redis..."
    )

    try:
        redis_connected = (
            await chat_service
            .quota_service
            .check_connection()
        )

        if redis_connected:
            print(
                "[VERSIN] Redis disponível."
            )

        else:
            print(
                (
                    "[VERSIN] Redis indisponível. "
                    "A IA continuará funcionando, "
                    "mas a quota não será persistida."
                )
            )

    except Exception as error:
        print(
            (
                "[VERSIN] Falha ao testar Redis: "
                f"{type(error).__name__}: "
                f"{error}"
            )
        )

    print()

    # ========================================================
    # APLICAÇÃO ATIVA
    # ========================================================

    yield

    # ========================================================
    # SHUTDOWN
    # ========================================================

    print()
    print(
        "[VERSIN] Encerrando serviços..."
    )

    try:
        await chat_service.close()

    except Exception as error:
        print(
            (
                "[VERSIN] Erro ao encerrar serviços: "
                f"{type(error).__name__}: "
                f"{error}"
            )
        )

    print(
        "[VERSIN] Serviços encerrados."
    )

    print()


# ============================================================
# FASTAPI
# ============================================================

app = FastAPI(
    title=settings.PROJECT_NAME,
    lifespan=lifespan,
)


# ============================================================
# CORS
# ============================================================
#
# Permite que o Flutter Web faça requisições para a API
# hospedada no Render.
#
# Sem esta configuração:
#
# Flutter Web
#     ↓
# https://versin.onrender.com
#     ↓
# navegador bloqueia por CORS
#
# Mesmo que o backend responda HTTP 200.
#
# IMPORTANTE:
#
# Não utilizamos:
#
# allow_origins=["*"]
#
# porque o Versin envia Authorization: Bearer <JWT> e é melhor
# manter uma allowlist explícita.
#
# Adicione aqui o domínio Web de produção quando ele existir.
#
# ============================================================

CORS_ALLOWED_ORIGINS = [
    # ========================================================
    # DESENVOLVIMENTO LOCAL
    # ========================================================

    "http://localhost:8080",
    "http://127.0.0.1:8080",

    # ========================================================
    # PRODUÇÃO
    # ========================================================
    #
    # Exemplos futuros:
    #
    # "https://versin.com",
    # "https://app.versin.com",
    #
    # ========================================================
]


app.add_middleware(
    CORSMiddleware,

    # ========================================================
    # ORIGENS
    # ========================================================

    allow_origins=CORS_ALLOWED_ORIGINS,

    # ========================================================
    # CREDENCIAIS
    # ========================================================
    #
    # Mantemos habilitado para permitir fluxos autenticados.
    #
    # ========================================================

    allow_credentials=True,

    # ========================================================
    # MÉTODOS HTTP
    # ========================================================
    #
    # GET
    # POST
    # PUT
    # PATCH
    # DELETE
    # OPTIONS
    #
    # ========================================================

    allow_methods=[
        "*",
    ],

    # ========================================================
    # HEADERS
    # ========================================================
    #
    # Necessário principalmente para:
    #
    # Authorization
    # Content-Type
    # Accept
    #
    # ========================================================

    allow_headers=[
        "*",
    ],
)


# ============================================================
# DISPONIBILIZAR CHAT SERVICE
# ============================================================
#
# chat_route.py acessa:
#
# request.app.state.chat_service
#
# ============================================================

app.state.chat_service = (
    chat_service
)


# ============================================================
# ROTAS
# ============================================================

app.include_router(
    chat_router
)


# ============================================================
# HEALTH CHECK SIMPLES
# ============================================================
#
# GET /
#
# ============================================================

@app.get("/")
async def health_check():
    return {
        "status":
            "online",

        "project":
            settings.PROJECT_NAME,

        "provider":
            "Groq",

        "model":
            settings.GROQ_MODEL,

        "message":
            (
                f"{settings.PROJECT_NAME} "
                "is operational"
            ),
    }


# ============================================================
# HEALTH CHECK DETALHADO
# ============================================================
#
# GET /health
#
# ============================================================

@app.get(
    "/health"
)
async def health():
    quota_service = (
        chat_service.quota_service
    )

    return {
        "status":
            "healthy",

        "project":
            settings.PROJECT_NAME,

        "ai": {
            "provider":
                "Groq",

            "model":
                settings.GROQ_MODEL,

            "monthly_user_token_limit":
                settings.AI_MONTHLY_TOKEN_LIMIT,

            "global_daily_token_limit":
                settings.AI_GLOBAL_DAILY_TOKEN_LIMIT,

            "rate_limit_per_minute":
                settings.AI_RATE_LIMIT_PER_MINUTE,

            "max_input_length":
                settings.AI_MAX_INPUT_LENGTH,
        },

        "redis": {
            "available":
                quota_service.redis_available,
        },

        # ====================================================
        # CORS
        # ====================================================
        #
        # Útil para diagnóstico.
        #
        # Não contém segredo.
        #
        # ====================================================

        "cors": {
            "allowed_origins":
                CORS_ALLOWED_ORIGINS,
        },
    }


# ============================================================
# EXECUÇÃO LOCAL
# ============================================================
#
# Pode iniciar com:
#
# python main.py
#
# ou:
#
# python -m uvicorn main:app --reload
#
# ============================================================

if __name__ == "__main__":
    import uvicorn

    uvicorn.run(
        "main:app",
        host="0.0.0.0",
        port=settings.PORT,
        reload=True,
    )