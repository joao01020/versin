from pydantic import BaseModel, Field
from typing import List, Optional, Dict

class ChatRequest(BaseModel):
    user_id: str = Field(default="default_user", description="Identificador único do usuário")
    message: str = Field(..., description="Mensagem ou letra enviada para análise")
    current_list: List[str] = Field(default_factory=list, description="Lista de rimas para suporte")
    private_api_key: Optional[str] = Field(default=None, description="Chave Groq do usuário (opcional)")
    history_context: Optional[Dict] = Field(
        default_factory=dict, 
        description="Contexto do estúdio (BPM, Vibe, Técnica, Estrutura)"
    )

    class Config:
        # Isso ajuda o FastAPI a gerar um exemplo bonito no Swagger (/docs)
        json_schema_extra = {
            "example": {
                "user_id": "user_123",
                "message": "Minha rima aqui...",
                "current_list": ["flow", "show"],
                "history_context": {
                    "bpm": 90,
                    "vibe": "Boombap",
                    "technique": "Multi-sílabas",
                    "structure": "Verso"
                }
            }
        }