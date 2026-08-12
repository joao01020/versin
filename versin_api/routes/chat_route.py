from fastapi import APIRouter, Request

from models.schemas import ChatRequest


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/chat",
    tags=["chat"],
)


# ============================================================
# POST /chat
# ============================================================
#
# Esta rota não contém regra de negócio.
#
# Ela apenas:
#
# 1. recebe o ChatRequest;
# 2. pega o ChatService criado no main.py;
# 3. envia os dados para ChatService.process();
# 4. devolve a resposta para o Flutter.
#
# ============================================================

@router.post("")
async def chat(
    data: ChatRequest,
    request: Request,
):
    chat_service = (
        request
        .app
        .state
        .chat_service
    )

    return await chat_service.process(
        data
    )


# ============================================================
# STATUS DA QUOTA DO USUÁRIO
# ============================================================
#
# Essa rota será útil para:
#
# Dashboard
# Settings
# barra "IA mensal"
#
# Exemplo:
#
# GET /chat/quota/user_123
#
# ============================================================

@router.get(
    "/quota/{user_id}"
)
async def get_quota_status(
    user_id: str,
    request: Request,
):
    chat_service = (
        request
        .app
        .state
        .chat_service
    )

    return await (
        chat_service
        .quota_service
        .get_status(
            user_id
        )
    )


# ============================================================
# STATUS DO RATE LIMIT
# ============================================================
#
# Útil para debug/admin.
#
# Exemplo:
#
# GET /chat/rate-limit/user_123
#
# ============================================================

@router.get(
    "/rate-limit/{user_id}"
)
async def get_rate_limit_status(
    user_id: str,
    request: Request,
):
    chat_service = (
        request
        .app
        .state
        .chat_service
    )

    return await (
        chat_service
        .rate_limiter
        .get_status(
            user_id
        )
    )