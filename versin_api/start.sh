#!/bin/bash

# Garante que as dependências existam no ambiente do Render
pip install --upgrade pip
pip install gunicorn uvicorn fastapi groq python-dotenv google-generativeai

# Inicia o servidor apontando para o arquivo principal
python -m gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT