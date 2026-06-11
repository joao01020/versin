from fastapi import FastAPI, Depends, HTTPException
from core.config import settings
from core.security import get_safe_key
from models.schemas import ChatRequest
from services.ai_service import AIService
from services.prompt_engine import create_producer_prompt
from services.quota_service import QuotaService

# Inicialização da aplicação
app = FastAPI(title=settings.PROJECT_NAME)

# Instância única do serviço de quota para controle de uso
quota_service = QuotaService()

# Dependência para injetar o serviço de IA com a chave segura
def get_ai_service(data: ChatRequest):
    key = get_safe_key(data.private_api_key, settings.GROQ_API_KEY)
    if not key:
        raise HTTPException(status_code=500, detail="API Key not configured.")
    return AIService(key)

@app.get("/")
async def health_check():
    """Rota de Health Check para manter o serviço ativo."""
    return {"status": "online", "message": f"{settings.PROJECT_NAME} is operational"}

@app.post("/chat")
async def chat_versin(
    data: ChatRequest, 
    ai: AIService = Depends(get_ai_service)
):
    """Rota principal com verificação de quota e processamento de IA."""
    
    # 1. Validação de Limite (Fail-Fast)
    if not await quota_service.check_limit(data.user_id):
        raise HTTPException(
            status_code=429, 
            detail="Usage limit exceeded. Please acquire more credits."
        )
    
    # 2. Seleção de modelo (Pro vs Normal)
    model = "llama-3.3-70b-versatile" if data.private_api_key else "llama-3.1-8b-instant"
    
    # 3. Geração de prompt
    prompt = create_producer_prompt(
        context=data.history_context or {}, 
        rhymes=data.current_list or []
    )
    
    try:
        # 4. Execução da análise via serviço de IA
        result = await ai.get_analysis(model, prompt, data.message)
        
        # 5. Registro de consumo (1 request = 50 unidades de quota)
        await quota_service.register_usage(data.user_id, 50)
        
        return {
            "role": "assistant",
            "content": result.get("content", "No feedback available."),
            "is_acceptable": result.get("is_acceptable", False),
            "impact_level": result.get("impact_level", 1),
            "feedback_reason": result.get("feedback_reason", "Analysis complete.")
        }
        
    except Exception as e:
        # Log de erro para rastreabilidade
        print(f"CRITICAL ERROR: {str(e)}")
        return {
            "role": "assistant", 
            "content": "Brain connection error. Please try again.", 
            "impact_level": 1
        }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.PORT)