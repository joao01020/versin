import logging
from typing import Optional

# Configuração de logger para monitorar tentativas de uso de chaves externas
logger = logging.getLogger("security")

def validar_api_key_usuario(api_key: Optional[str]) -> bool:
    """
    Valida se a chave fornecida pelo usuário possui o formato esperado
    da Groq antes de realizar qualquer chamada externa.
    """
    if not api_key:
        return False
    
    # Validação de formato (As chaves da Groq seguem o padrão gsk_...)
    is_valid = api_key.startswith("gsk_") and len(api_key) > 20
    
    if not is_valid:
        logger.warning("Tentativa de uso de API Key inválida bloqueada.")
        
    return is_valid

def get_safe_key(user_key: Optional[str], default_key: str) -> str:
    """
    Retorna a chave do usuário se for válida, caso contrário, 
    retorna a chave padrão do servidor (fallback).
    """
    if validar_api_key_usuario(user_key):
        logger.info("Utilizando API Key fornecida pelo usuário.")
        return user_key
    
    # Se a chave do usuário não for válida, logamos que caímos no fallback
    if user_key and user_key.strip():
        logger.warning("Chave do usuário inválida. Revertendo para chave padrão do servidor.")
        
    return default_key