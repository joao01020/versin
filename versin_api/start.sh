#!/bin/bash

# Instala as dependências necessárias
pip install -r requirements.txt

# Inicia o servidor diretamente com Uvicorn (mais estável para FastAPI)
# O Gunicorn é ótimo, mas para uma única instância no Render, o Uvicorn é mais direto
python -m uvicorn main:app --host 0.0.0.0 --port $PORT