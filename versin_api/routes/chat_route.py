from fastapi import APIRouter, HTTPException, Request

from models.schemas import ChatRequest, ChatResponse


# ============================================================
# ROUTER
# ============================================================

router = APIRouter(
    prefix="/chat",
    tags=["chat"],
)


# ============================================================
# HELPERS
# ============================================================

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

    if len(normalized) > 128:
        raise HTTPException(
            status_code=400,
            detail="Usuário inválido.",
        )

    return normalized


def _get_chat_service(
    request: Request,
):
    chat_service = getattr(
        request.app.state,
        "chat_service",
        None,
    )

    if chat_service is None:
        raise HTTPException(
            status_code=503,
            detail=(
                "Serviço de chat "
                "não está disponível."
            ),
        )

    return chat_service


# ============================================================
# POST /chat
# ============================================================
#
# Fluxo:
#
# Flutter
#   ↓
# ChatRequest
#   ↓
# ChatService.process()
#   ↓
# ChatResponse
#
# ============================================================

@router.post(
    "",
    response_model=ChatResponse,
)
async def chat(
    data: ChatRequest,
    request: Request,
) -> ChatResponse:
    chat_service = (
        _get_chat_service(
            request
        )
    )

    result = await (
        chat_service.process(
            data
        )
    )

    return ChatResponse(
        **result
    )


# ============================================================
# STATUS DA QUOTA
# ============================================================
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
) -> dict:
    normalized_user_id = (
        _normalize_user_id(
            user_id
        )
    )

    chat_service = (
        _get_chat_service(
            request
        )
    )

    return await (
        chat_service
        .quota_service
        .get_status(
            normalized_user_id
        )
    )


# ============================================================
# STATUS DO RATE LIMIT
# ============================================================
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
) -> dict:
    normalized_user_id = (
        _normalize_user_id(
            user_id
        )
    )

    chat_service = (
        _get_chat_service(
            request
        )
    )

    return await (
        chat_service
        .rate_limiter
        .get_status(
            normalized_user_id
        )
    )