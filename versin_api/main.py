import os
import uvicorn
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from dotenv import load_dotenv
from groq import Groq

load_dotenv()
api_key = os.getenv("GROQ_API_KEY")
client = Groq(api_key=api_key)

app = FastAPI(title="Versin AI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

class RequestData(BaseModel):
    texto_usuario: str
    lista_rimas: list[str]
    is_comando: bool = False

@app.post("/processar")
async def processar_versin(data: RequestData):
    try:
        # Se não houver texto ou lista vazia, retorna nada imediatamente
        if not data.texto_usuario.strip() or not data.lista_rimas:
            return {"resultado": ""}

        # SYSTEM PROMPT RÍGIDO: Transforma a IA em um filtro de busca
        system_instructions = (
            "Você é um motor de busca fonética estrito. "
            f"Sua ÚNICA função é escolher UMA palavra desta lista: {data.lista_rimas}. "
            "REGRAS TÉCNICAS: "
            "1. Analise a rima final do texto do usuário. "
            "2. Responda APENAS com a palavra da lista que melhor rima. "
            "3. NUNCA invente palavras fora da lista. "
            "4. Se nenhuma palavra da lista rimar, responda exatamente: NENHUMA. "
            "5. Proibido explicações ou frases. Apenas a palavra seca."
        )

        user_prompt = f"Selecione da lista a rima para: '{data.texto_usuario}'"

        completion = client.chat.completions.create(
            model="llama-3.3-70b-versatile", 
            messages=[
                {"role": "system", "content": system_instructions},
                {"role": "user", "content": user_prompt}
            ],
            temperature=0.0, # ZERO criatividade para não fugir da lista
            max_tokens=10    # Suficiente para 1 palavra
        )

        resultado = completion.choices[0].message.content.strip()
        
        # Limpeza e Validação Final: Se não estiver na lista, descarta
        resultado_limpo = resultado.replace('"', '').replace('.', '').strip()
        
        palavras_validas = [p.lower() for p in data.lista_rimas]
        
        if resultado_limpo.lower() in palavras_validas:
            print(f"Versin Escolheu: {resultado_limpo}")
            return {"resultado": resultado_limpo}
        
        print(f"Nenhuma rima válida encontrada para: {data.texto_usuario}")
        return {"resultado": ""}

    except Exception as e:
        print(f"ERRO NO BACKEND: {str(e)}")
        return {"resultado": ""} # Retorna vazio para não travar o Flutter

if __name__ == "__main__":
    uvicorn.run(app, host="127.0.0.1", port=8000)