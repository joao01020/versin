#!/bin/bash
# 1. Instala as rimas e dependências no servidor
pip install gunicorn uvicorn fastapi groq python-dotenv

# 2. Liga o motor usando a porta dinâmica do Render ($PORT)
python -m gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:$PORT