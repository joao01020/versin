import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    PROJECT_NAME: str = "Versin AI Pro"
    GROQ_API_KEY: str = os.getenv("GROQ_API_KEY", "")
    PORT: int = int(os.getenv("PORT", 8000))
    # Adicione aqui futuras variáveis como banco de dados
    # DATABASE_URL: str = os.getenv("DATABASE_URL", "")

settings = Settings()