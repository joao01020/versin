import os
import uvicorn
import google.generativeai as genai
import json
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Optional, Dict
from dotenv import load_dotenv
from groq import Groq
from datetime import datetime
from functools import lru_cache

load_dotenv()

# CONFIGURAÇÕES DE API
GROQ_API_KEY = os.getenv("GROQ_API_KEY")
GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")

client_groq_default = Groq(api_key=GROQ_API_KEY) if GROQ_API_KEY else None

if GEMINI_API_KEY:
    genai.configure(api_key=GEMINI_API_KEY)
    gemini_model = genai.GenerativeModel('gemini-1.5-flash')
else:
    gemini_model = None

app = FastAPI(title="Versin AI Pro - Estúdio")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Sincronizado com RhymesController.dart (onTextChanged)
class RequestData(BaseModel):
    user_text: str
    rhyme_list: List[str]
    private_api_key: Optional[str] = None
    style_config: Optional[Dict] = {}

# Sincronizado com RhymesController.dart (fetchAiResponse)
class ChatRequest(BaseModel):
    user_id: Optional[str] = "default_user"
    message: str
    current_list: Optional[List[str]] = []
    private_api_key: Optional[str] = None
    style_config: Optional[Dict] = {}

def get_groq_client(user_key: Optional[str]):
    if user_key and user_key.strip():
        if user_key == "VERSIN-PRO-TRIAL-2026-FREE":
            return client_groq_default
        return Groq(api_key=user_key)
    return client_groq_default

# --- SISTEMA DE CACHE INTELIGENTE ---
@lru_cache(maxsize=2048)
def buscar_rima_na_ia_cached(texto_usuario, rimas_str, api_key_hash):
    """
    api_key_hash serve para diferenciar o cache entre usuários PRO e FREE
    sem expor a chave real na assinatura da função de cache.
    """
    client = get_groq_client(GROQ_API_KEY if api_key_hash == "DEFAULT" else api_key_hash)
    
    system_instructions = (
        "Você é um motor de busca de rimas e crítico de métrica para Trap/Rap. "
        "Retorne APENAS JSON: {"
        "'result': ['rima1', 'rima2', 'rima3'], "
        "'impact_level': 1_a_6, "
        "'feedback_reason': 'comentário_curto_técnico_e_ácido'"
        "}. "
        f"No feedback_reason, seja dinâmico. Base de rimas: {rimas_str}."
    )

    completion = client.chat.completions.create(
        model="llama-3.1-8b-instant", 
        messages=[
            {"role": "system", "content": system_instructions},
            {"role": "user", "content": f"Texto atual: '{texto_usuario}'"}
        ],
        temperature=0.3,
        response_format={"type": "json_object"},
        max_tokens=150
    )
    return completion.choices[0].message.content

# --- LÓGICA DE MODOS DINÂMICOS ---
def definir_comportamento(mensagem: str, lista_rimas: List[str]) -> str:
    msg = mensagem.lower()
    
    if "/modorima" in msg:
        return (
            "MODO RIMA ATIVO. Objetivo: Rimas raras e multissilábicas. "
            f"Biblioteca do artista: {lista_rimas}. "
            "Feedback: Analise a sonoridade técnica. Incentive o save no '+'."
        )
    elif "/modocompor" in msg:
        return (
            "MODO COMPOR ATIVO. Foco: Estrutura, métrica e flow. "
            "Feedback: Diga se o verso está pesado ou se atropela o compasso."
        )
    elif "/modolistar" in msg:
        return (
            "MODO LISTAR ATIVO. Foco: Curadoria de vocabulário. "
            f"Lista atual: {lista_rimas}. Feedback: Destaque a rima mais 'cara'."
        )
    elif "/modomarketing" in msg:
        return (
            "MODO MARKETING ATIVO. Foco: Viralização e Branding. "
            "Feedback: Avalie o potencial de 'trend' do verso para TikTok/Reels."
        )
    else:
        return (
            "Você é o Versin, Mentor de Elite. Seja sincero, técnico e detalhista.\n"
            f"Use a biblioteca {lista_rimas} como base.\n"
            "Analise impacto, clichês e flow (compasso 4/4). Use analogias de FL Studio."
        )

# --- ROTA DE RIMA (AVALIAÇÃO COM CACHE) ---
@app.post("/process")
async def processar_versin(data: RequestData):
    try:
        t = data.user_text.strip().lower()
        if not t or len(t) < 1:
            return {"result": [], "impact_level": 0, "feedback_reason": "Aguardando escrita..."}

        # Identificador de cache para não misturar chaves privadas
        key_id = data.private_api_key if data.private_api_key else "DEFAULT"
        rimas_str = ",".join(data.rhyme_list) if data.rhyme_list else ""
        
        # Busca no Cache ou na IA
        conteudo_ia = buscar_rima_na_ia_cached(t, rimas_str, key_id)
        res = json.loads(conteudo_ia)
        
        # Garantia de lista para o Flutter
        if isinstance(res.get('result'), str):
            res['result'] = [res['result']]
        elif res.get('result') is None:
            res['result'] = []
            
        return res
    except Exception as e:
        print(f"ERRO NO PROCESSAMENTO: {e}")
        return {"result": [], "impact_level": 1, "feedback_reason": "Sintonizando..."}

# --- ROTA DE CHAT (MODOS INTEGRADOS) ---
@app.post("/chat")
async def chat_versin(data: ChatRequest):
    try:
        is_pro = bool(data.private_api_key and data.private_api_key.strip())
        client = get_groq_client(data.private_api_key)
        model_chat = "llama-3.3-70b-versatile" if is_pro else "llama-3.1-8b-instant"

        system_behavior = definir_comportamento(data.message, data.current_list)
        system_behavior += (
            " Retorne APENAS JSON: {"
            "'content': 'resposta_em_markdown', "
            "'impact_level': 1_a_6, "
            "'feedback_reason': 'comentário_curto_termômetro'"
            "}. Níveis: 1-2 (Ok), 3-4 (Bom), 5-6 (Hit/Ouro)."
        )

        completion = client.chat.completions.create(
            model=model_chat,
            messages=[{"role": "system", "content": system_behavior}, {"role": "user", "content": data.message}],
            temperature=0.7,
            response_format={"type": "json_object"},
            max_tokens=1000
        )
        
        res_json = json.loads(completion.choices[0].message.content)
        return {
            "role": "assistant", 
            "content": res_json.get("content", ""),
            "impact_level": res_json.get("impact_level", 1),
            "feedback_reason": res_json.get("feedback_reason", "Análise Versin.")
        }

    except Exception as e:
        print(f"ERRO NO CHAT: {str(e)}")
        return {"role": "assistant", "content": "Erro na conexão cerebral.", "impact_level": 1, "feedback_reason": "Erro."}

if __name__ == "__main__":
    # Rodar com uvicorn localmente (para produção use gunicorn)
    uvicorn.run(app, host="0.0.0.0", port=8000)