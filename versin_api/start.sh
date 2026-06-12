#!/bin/bash

# Garante que o pip esteja atualizado antes de instalar qualquer coisa
pip install --upgrade pip

# Instala as dependências de forma que o pip tente resolver conflitos de forma inteligente
pip install --no-cache-dir -r requirements.txt

# Inicia o servidor com Uvicorn
# --workers pode ajudar se você tiver uma instância com mais de 512MB de RAM, 
# mas para começar, manter o workers padrão é mais seguro.
python -m uvicorn main:app --host 0.0.0.0 --port $PORT