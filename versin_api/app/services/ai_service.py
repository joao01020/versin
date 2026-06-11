from groq import Groq
import json

class AIService:
    def __init__(self, api_key: str):
        self.client = Groq(api_key=api_key)

    async def get_analysis(self, model: str, system_prompt: str, user_message: str):
        response = self.client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_message}
            ],
            response_format={"type": "json_object"}
        )
        return json.loads(response.choices[0].message.content)