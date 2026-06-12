# services/quota_service.py

class QuotaService:
    def __init__(self):
        # Em produção, substituir por consulta a banco de dados ou Redis
        self.usage_db = {} 

    async def check_limit(self, user_id: str) -> bool:
        # Exemplo: limite de 1000 tokens por usuário
        usuario_tokens = self.usage_db.get(user_id, 0)
        return usuario_tokens < 1000

    async def register_usage(self, user_id: str, tokens: int):
        self.usage_db[user_id] = self.usage_db.get(user_id, 0) + tokens