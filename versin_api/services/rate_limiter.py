import os
import redis.asyncio as redis # Note o .asyncio aqui
from fastapi import HTTPException
from dotenv import load_dotenv

load_dotenv()

class RateLimiter:
    def __init__(self, requests_per_minute: int = 5):
        redis_url = os.getenv("REDIS_URL")
        if not redis_url:
            raise ValueError("REDIS_URL não configurada no arquivo .env")
        
        # Conexão assíncrona
        self.r = redis.from_url(redis_url, decode_responses=True)
        self.limit = requests_per_minute

    async def check_rate_limit(self, user_id: str):
        key = f"rate:{user_id}"
        
        # Operações assíncronas com 'await'
        current = await self.r.incr(key)
        
        if current == 1:
            await self.r.expire(key, 60)
            
        if current > self.limit:
            raise HTTPException(
                status_code=429, 
                detail="Too many requests. Slow down!"
            )