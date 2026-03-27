#!/bin/bash

# Garante que o pip esteja atualizado e instala apenas o necessário
pip install --upgrade pip
pip install gunicorn uvicorn fastapi groq python-dotenv google-generativeai

# Inicia com 2 workers e um timeout maior para o Render não desistir
python -m gunicorn -w 2 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT --timeout 120