#!/bin/bash

# 1. Instala TODAS as dependências que o seu main.py pede (incluindo o Google SDK)
pip install gunicorn uvicorn fastapi groq python-dotenv google-generativeai

# 2. Inicia o servidor com a porta correta do Render
python -m gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT