from groq import AsyncGroq
import json
import logging

class AIService:
    def __init__(self, api_key: str):
        self.client = AsyncGroq(api_key=api_key)

    async def get_analysis(self, model: str, system_prompt: str, user_message: str):
        try:
            response = await self.client.chat.completions.create(
                model=model,
                messages=[
                    {"role": "system", "content": system_prompt},
                    {"role": "user", "content": user_message}
                ],
                response_format={"type": "json_object"}
            )
            
            content = response.choices[0].message.content
            # Debug: se a IA responder algo que não é JSON, vamos ver o que é
            return json.loads(content)
            
        except Exception as e:
            # Isso vai imprimir no seu terminal o erro real da API da Groq
            print(f"--- ERRO NA CHAMADA DA IA: {str(e)} ---")
            raise e