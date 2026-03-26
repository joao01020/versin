#!/bin/bash
source venv/bin/activate
echo "Iniciando Versin AI Pro com 4 Workers e Cache..."
gunicorn -w 4 -k uvicorn.workers.UvicornWorker main:app --bind 0.0.0.0:8000
