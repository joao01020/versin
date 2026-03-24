import os
import uvicorn
import google.generativeai as genai
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional
from dotenv import load_dotenv
from groq import Groq
from datetime import datetime

load_dotenv()

# CONFIGURAÇÕES DE API PADRÃO (SERVIDOR)
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

# Cliente padrão para usuários FREE
client_groq_default = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-1.5-flash')
else:
    gemini_model = None

app = FastAPI(title="Versin AI Pro")

# --- GESTÃO DE COTAS (MEMÓRIA) ---
user_quotas = {} 
LIMITE_DIARIO_FREE = 50 

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- MODELOS DE DADOS ---
class RequestData(BaseModel):
    texto_usuario: str
    lista_rimas: List[str]
    api_key_privada: Optional[str] = None

class ChatRequest(BaseModel):
    user_id: Optional[str] = "default_user"
    message: str
    lista_atual: Optional[List[str]] = []
    api_key_privada: Optional[str] = None

# --- FUNÇÃO AUXILIAR DE VELOCIDADE (O SEGREDO) ---
def get_groq_client(user_key: Optional[str]):
    """
    Se o usuário mandar uma chave, criamos um cliente instantâneo (Jato).
    Se não, usamos o cliente padrão do servidor (Busão).
    """
    if user_key and user_key.strip():
        # Se for a chave de Trial, usamos a nossa do servidor, mas com prioridade
        if user_key == "VERSIN-PRO-TRIAL-2026-FREE":
            return client_groq_default
        return Groq(api_key=user_key)
    return client_groq_default

# --- ROTA DE RIMA (BALÃO DE SUGESTÃO) ---
@app.post("/processar")
async def processar_versin(data: RequestData):
    try:
        if not data.texto_usuario.strip() or not data.lista_rimas:
            return {"resultado": ""}

        client = get_groq_client(data.api_key_privada)
        if not client:
            raise HTTPException(status_code=500, detail="Groq não configurado")

        # No modo rima, usamos o modelo mais rápido (8b) para o balão não travar
        model_to_use = "llama-3.1-8b-instant" 
        
        system_instructions = (
            "Você é um consultor de rimas fonéticas de música urbana. "
            f"Escolha UMA palavra desta lista: {data.lista_rimas}. "
            "REGRAS: Rime com a última palavra do usuário. Faça sentido. "
            "Responda APENAS a palavra ou NENHUMA."
        )

        completion = client.chat.completions.create(
            model=model_to_use, 
            messages=[
                {"role": "system", "content": system_instructions},
                {"role": "user", "content": f"Contexto: '{data.texto_usuario}'"}
            ],
            temperature=0.1, # Menor temperatura = mais rápido e certeiro
            max_tokens=10,
            timeout=2.0 # Timeout curto para não travar o Flutter
        )

        resultado = completion.choices[0].message.content.strip().replace('"', '').replace('.', '')
        return {"resultado": "NENHUMA" if "NENHUMA" in resultado.upper() else resultado}
    except Exception as e:
        print(f"ERRO RIMA: {str(e)}")
        return {"resultado": ""}

# --- ROTA DE CHAT (MENTOR) ---
@app.post("/chat")
async def chat_versin(data: ChatRequest):
    try:
        # 1. VERIFICAÇÃO DE COTAS (Ignorada no PRO TRIAL ou PRIVADA)
        is_pro = data.api_key_privada is not None and data.api_key_privada.strip() != ""
        
        if not is_pro:
            hoje = datetime.now().strftime("%Y-%m-%d")
            u_id = data.user_id if data.user_id else "anon"
            quota_key = f"{u_id}_{hoje}"
            count = user_quotas.get(quota_key, 0)
            
            if count >= LIMITE_DIARIO_FREE:
                return {
                    "role": "assistant", 
                    "content": "⚠️ **Limite Diário Atingido**. No modo **FREE** você tem 50 mensagens. Ative o **PRO TRIAL** ou use sua **API Key**."
                }
            user_quotas[quota_key] = count + 1

        # 2. SELEÇÃO DE CLIENTE
        client = get_groq_client(data.api_key_privada)
        
        # Se for Pro/Privada usamos o modelo forte (70b), se for Free usamos o 8b pra economizar
        model_chat = "llama-3.3-70b-versatile" if is_pro else "llama-3.1-8b-instant"

        system_behavior = (
            "Você é o Versin, Mentor de Trap/Rap. Analise o sentimento e o flow. "
            f"Vocabulário do artista: {data.lista_atual}. "
            "Estilo: Curto, direto, gírias de estúdio, **negrito** em termos técnicos."
        )

        try:
            completion = client.chat.completions.create(
                model=model_chat,
                messages=[{"role": "system", "content": system_behavior}, {"role": "user", "content": data.message}],
                temperature=0.7,
                max_tokens=800,
                timeout=10.0
            )
            return {"role": "assistant", "content": completion.choices[0].message.content.strip()}
        
        except Exception as e:
            # Fallback para Gemini apenas se não houver chave privada dando erro
            if not is_pro and gemini_model:
                response = gemini_model.generate_content(f"Aja como Versin Mentor. {system_behavior}. Usuário: {data.message}")
                return {"role": "assistant", "content": response.text}
            return {"role": "assistant", "content": f"Erro na conexão (IA): {str(e)}"}

    except Exception as e:
        print(f"ERRO CHAT: {str(e)}")
        return {"role": "assistant", "content": "Erro crítico no **backend**."}

if __name__ == "__main__":
    # Roda em 0.0.0.0 para aceitar conexões externas (celular na mesma rede)
    uvicorn.run(app, host="0.0.0.0", port=8000)