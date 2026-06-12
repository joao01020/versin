import os
from pathlib import Path
from dotenv import load_dotenv
from fastapi import FastAPI, HTTPException
from core.config import settings
from core.security import get_safe_key
from models.schemas import ChatRequest
from services.ai_service import AIService
from services.prompt_engine import create_producer_prompt
from services.quota_service import QuotaService
from services.safety_service import SafetyService
from services.rate_limiter import RateLimiter

# Carregamento robusto das variáveis de ambiente na raiz
BASE_DIR = Path(__file__).resolve().parent
load_dotenv(dotenv_path=BASE_DIR / ".env")

# Inicialização da aplicação
app = FastAPI(title=settings.PROJECT_NAME)

# Instâncias de serviços globais
quota_service = QuotaService()
safety_service = SafetyService()
limiter = RateLimiter(requests_per_minute=5)

@app.get("/")
async def health_check():
    return {"status": "online", "message": f"{settings.PROJECT_NAME} is operational"}

@app.post("/chat")
async def chat_versin(data: ChatRequest):
    """Rota principal com fluxo de execução linear e seguro."""

    # 1. Proteção contra Abuso (Rate Limiting)
    await limiter.check_rate_limit(data.user_id)

    # 2. Validação de Limite de Créditos
    if not await quota_service.check_limit(data.user_id):
        raise HTTPException(
            status_code=429,
            detail="Usage limit exceeded. Please acquire more credits."
        )

    # 3. Inicialização do serviço de IA dentro da rota
    api_key = get_safe_key(data.private_api_key, settings.GROQ_API_KEY)
    if not api_key:
        raise HTTPException(status_code=500, detail="API Key not configured.")
    ai = AIService(api_key)

    # 4. Sanitização da Entrada
    clean_message = safety_service.sanitize_input(data.message)

    # 5. Definição de modelo
    model = "llama-3.3-70b-versatile" if data.private_api_key else "llama-3.1-8b-instant"

    # 6. Geração de prompt
    prompt = create_producer_prompt(
        context=data.history_context or {},
        rhymes=data.current_list or []
    )

    try:
        # 7. Execução da análise
        result = await ai.get_analysis(model, prompt, clean_message)

        # 8. Validação de Segurança da Saída
        if not safety_service.is_content_safe(result):
            return {
                "role": "assistant",
                "content": "Analysis blocked due to safety policies.",
                "impact_level": 1
            }

        # 9. Registro de consumo
        await quota_service.register_usage(data.user_id, 50)

        return {
            "role": "assistant",
            "content": result.get("content") or "No feedback available.",
            "is_acceptable": bool(result.get("is_acceptable", False)),
            "impact_level": int(result.get("impact_level", 1)),
            "feedback_reason": result.get("feedback_reason") or "Analysis complete."
        }

    except Exception as e:
        # Logamos o erro internamente para você ver no terminal, mas devolvemos uma mensagem genérica para o usuário
        print(f"CRITICAL ERROR: {str(e)}")
        raise HTTPException(status_code=500, detail="Brain connection error.")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=settings.PORT)