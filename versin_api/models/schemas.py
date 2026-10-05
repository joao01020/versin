from typing import Any, Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class ChatRequest(BaseModel):
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    model_config = ConfigDict(
        extra="ignore",
        str_strip_whitespace=True,
        json_schema_extra={
            "example": {
                "user_id": "user_123",
                "message": "Minha rima aqui...",
                "current_list": [
                    "flow",
                    "show",
                ],
                "private_api_key": None,
                "history_context": {
                    "bpm": 90,
                    "vibe": "Boombap",
                    "technique": "Multi-sílabas",
                    "structure": "Verso",
                },
            }
        },
    )

    # ============================================================
    # USUÁRIO
    # ============================================================

    user_id: str = Field(
        ...,
        min_length=1,
        max_length=128,
        description=(
            "Identificador único do usuário "
            "usado também para controle de quota."
        ),
    )

    # ============================================================
    # MENSAGEM
    # ============================================================

    message: str = Field(
        ...,
        min_length=1,
        max_length=12_000,
        description=(
            "Mensagem, pergunta ou trecho da letra "
            "enviado para análise."
        ),
    )

    # ============================================================
    # BANCO / TIMELINE DE RIMAS
    # ============================================================

    current_list: List[str] = Field(
        default_factory=list,
        max_length=100,
        description=(
            "Lista atual de palavras/rimas "
            "usada como contexto adicional."
        ),
    )

    # ============================================================
    # API PRIVADA
    # ============================================================

    private_api_key: Optional[str] = Field(
        default=None,
        max_length=512,
        description=(
            "Chave privada da Groq fornecida "
            "pelo usuário, quando aplicável."
        ),
    )

    # ============================================================
    # CONTEXTO DO STUDIO
    # ============================================================

    history_context: Dict[str, Any] = Field(
        default_factory=dict,
        description=(
            "Contexto do Studio, vibe, "
            "técnica e estrutura."
        ),
    )


class ChatUsage(BaseModel):
    # ============================================================
    # TOKENS
    # ============================================================

    input_tokens: int = Field(
        default=0,
        ge=0,
    )

    output_tokens: int = Field(
        default=0,
        ge=0,
    )

    total_tokens: int = Field(
        default=0,
        ge=0,
    )


class ChatResponse(BaseModel):
    # ============================================================
    # RESPOSTA
    # ============================================================

    role: str = Field(
        default="assistant",
    )

    content: str = Field(
        ...,
        min_length=1,
    )

    is_acceptable: bool = Field(
        default=True,
    )

    impact_level: int = Field(
        default=1,
        ge=1,
        le=5,
    )

    feedback_reason: str = Field(
        default="Análise concluída.",
    )

    # ============================================================
    # USO
    # ============================================================

    usage: Optional[ChatUsage] = None

    # ============================================================
    # QUOTA
    # ============================================================

    quota: Optional[Dict[str, Any]] = None