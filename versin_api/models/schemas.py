from typing import Dict, List, Optional

from pydantic import BaseModel, ConfigDict, Field


class ChatRequest(BaseModel):
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    model_config = ConfigDict(
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
        }
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
        max_length=12000,
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
        description=(
            "Chave privada da Groq fornecida "
            "pelo usuário, quando aplicável."
        ),
    )

    # ============================================================
    # CONTEXTO DO STUDIO
    # ============================================================

    history_context: Dict[str, object] = Field(
        default_factory=dict,
        description=(
            "Contexto do Studio, vibe, "
            "técnica e estrutura."
        ),
    )