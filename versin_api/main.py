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

class RequestData(BaseModel):
    texto_usuario: str
    lista_rimas: List[str]
    api_key_privada: Optional[str] = None

class ChatRequest(BaseModel):
    user_id: Optional[str] = "default_user"
    message: str
    lista_atual: Optional[List[str]] = []
    api_key_privada: Optional[str] = None

def get_groq_client(user_key: Optional[str]):
    if user_key and user_key.strip():
        if user_key == "VERSIN-PRO-TRIAL-2026-FREE":
            return client_groq_default
        return Groq(api_key=user_key)
    return client_groq_default

# --- LÓGICA DE MODOS DINÂMICOS ---
def definir_comportamento(mensagem: str, lista_rimas: List[str]) -> str:
    msg = mensagem.lower()
    
    # MODO RIMA
    if "/modorima" in msg:
        return (
            "Você está no MODO RIMA. Seu único objetivo é encontrar rimas perfeitas, multissilábicas e raras. "
            f"Base de rimas do artista: {lista_rimas}. "
            "Sempre que o usuário mandar uma palavra ou frase, retorne uma lista formatada de rimas. "
            "Seja técnico sobre a terminação das palavras (ex: rimas agudas, graves). "
            "Incentive o uso do botão '+' para salvar."
        )
    
    # MODO COMPOR
    elif "/modocompor" in msg:
        return (
            "Você está no MODO COMPOR. Foque 100% na estrutura da letra (Verso, Refrão, Bridge). "
            "Analise a métrica (contagem de sílabas poéticas) e o flow. "
            "Sugira variações de cadência e ajude a organizar a história da letra. "
            "Seja um mestre da escrita criativa e técnica."
        )
    
    # MODO LISTAR
    elif "/modolistar" in msg:
        return (
            "Você está no MODO LISTAR. Organize o vocabulário do artista. "
            f"Lista atual: {lista_rimas}. "
            "Separe as rimas por 'Prioridade Máxima' (as mais complexas) e 'Lista Total'. "
            "Dê sugestões de como combinar palavras dessa lista para criar punchlines."
        )
    
    # MODO MARKETING
    elif "/modomarketing" in msg:
        return (
            "Você é a Especialista em Marketing para Artistas Independentes. "
            "Foque em: retenção de ouvintes, algoritmos do Spotify/TikTok e branding visual. "
            "Dê estratégias GRÁTIS (trends, networking, Reels) e PAGAS (Tráfego pago, editais). "
            "Seja estratégica, direta e mostre como converter seguidor em fã real."
        )
    
    # MODO PADRÃO (MENTOR SINCERO, TÉCNICO E DETALHISTA)
    else:
        return (
            "Você é o Versin, Mentor de Elite de Trap, Rap e Funk, e Engenheiro de Mixagem experiente. "
            "Sua missão é transformar rascunhos em hits de impacto profissional através de uma mentoria sincera e detalhista.\n\n"
            
            "REGRAS DE REPERTÓRIO ({lista_rimas}):\n"
            "1. Se a {lista_rimas} estiver VAZIA: Avise que a biblioteca está limpa e peça permissão para sugerir rimas novas.\n"
            "2. Se a {lista_rimas} tiver conteúdo: Selecione APENAS as 3 rimas que melhor se encaixam no contexto da letra atual. Nunca envie a lista completa para não poluir o chat.\n"
            "3. Mix de Sugestões: Se o artista permitir rimas novas, envie no máximo: [3 rimas da lista dele + 3 rimas inéditas do Versin].\n"
            "4. Respeite a decisão: Se ele quiser manter apenas as dele, não sugira nada de fora. Se ele quiser apenas novas, ignore a lista salva.\n\n"

            "DIRETRIZES DE ORIENTAÇÃO PARA FINALIZAÇÃO:\n"
            "1. ANÁLISE DE IMPACTO E CLICHÊS: Identifique rimas óbvias e sugira 'Rimas Ricas' ou 'Internas'. Explique por que a troca deixa o verso mais 'caro'.\n\n"
            
            "2. CADÊNCIA E MÉTRICA: Analise se os versos cabem no compasso 4/4. Sugira cortes de conectivos (que, e, então) para o flow não atropelar e o silêncio criar o groove.\n\n"
            
            "3. ESTRUTURA DA MÚSICA: Verifique se falta Intro, Ponte ou Refrão. No refrão, priorize rimas com vogais abertas (A, O) para maior impacto sonoro.\n\n"
            
            "4. ENGENHARIA FL STUDIO (SIMPLICIDADE): Explique mixagem com analogias reais. Ex: 'O Reverb é como cantar no banheiro: dá espaço, mas se exagerar, vira uma bagunça de eco'.\n\n"
            
            "5. O VEREDITO DO MENTOR: Se a letra estiver pronta para o estúdio, mande um 'ESSE É O HIT!'. Caso contrário, dê uma nota de 1 a 10 (Nível de Fogo) e aponte o erro fatal."
        )
# --- ROTA DE RIMA (AVALIAÇÃO) ---
@app.post("/processar")
async def processar_versin(data: RequestData):
    try:
        t = data.texto_usuario.strip()
        if not t or len(t) < 1: # Reduzi para 1 para aceitar buscas rápidas
            return {"resultado": "NENHUMA", "nivel_impacto": 0, "motivo_feedback": "Aqueça a caneta..."}

        client = get_groq_client(data.api_key_privada)
        model_to_use = "llama-3.1-8b-instant" 
        
        system_instructions = (
            "Você é um motor de busca de rimas. "
            "Retorne APENAS JSON: {'resultado': 'palavra', 'nivel_impacto': 1_a_6, 'motivo_feedback': '...'}. "
            f"Contexto: {data.lista_rimas}."
        )

        completion = client.chat.completions.create(
            model=model_to_use, 
            messages=[
                {"role": "system", "content": system_instructions},
                {"role": "user", "content": f"Busque rima para: '{t}'"}
            ],
            temperature=0.2,
            response_format={"type": "json_object"},
            max_tokens=150
        )

        res = json.loads(completion.choices[0].message.content)
        return res
    except Exception:
        return {"resultado": "NENHUMA", "nivel_impacto": 1, "motivo_feedback": "Processando..."}

# --- ROTA DE CHAT (MODOS INTEGRADOS) ---
@app.post("/chat")
async def chat_versin(data: ChatRequest):
    try:
        is_pro = bool(data.api_key_privada and data.api_key_privada.strip())
        client = get_groq_client(data.api_key_privada)
        model_chat = "llama-3.3-70b-versatile" if is_pro else "llama-3.1-8b-instant"

        # Define o comportamento com base na mensagem (Comandos de modo)
        system_behavior = definir_comportamento(data.message, data.lista_atual)
        
        # Adiciona a regra universal do JSON
        system_behavior += (
            " Retorne APENAS JSON: {"
            "'content': 'resposta_em_markdown', "
            "'nivel_impacto': 1_a_6, "
            "'motivo_feedback': 'feedback_curto_para_o_termometro'"
            "}. Níveis: 1-2 (Ok), 3-4 (Interessante), 5-6 (Master/Marketing-Ouro)."
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
            "nivel_impacto": res_json.get("nivel_impacto", 1),
            "motivo_feedback": res_json.get("motivo_feedback", "Versin em modo dinâmico.")
        }

    except Exception as e:
        print(f"ERRO CHAT: {str(e)}")
        return {"role": "assistant", "content": "Erro no cérebro do Versin.", "nivel_impacto": 1, "motivo_feedback": "Erro."}

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8000)