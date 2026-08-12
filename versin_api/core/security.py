from typing import Optional


# ============================================================
# NORMALIZAR CHAVE
# ============================================================

def _normalize_key(
    api_key: Optional[str],
) -> Optional[str]:
    if api_key is None:
        return None

    normalized = api_key.strip()

    if not normalized:
        return None

    return normalized


# ============================================================
# OBTER API KEY SEGURA
# ============================================================
#
# PRIORIDADE:
#
# 1. API privada fornecida pelo usuário
# 2. API padrão do Versin
#
# Nunca imprime ou registra a chave.
#
# ============================================================

def get_safe_key(
    private_api_key: Optional[str],
    default_api_key: Optional[str],
) -> Optional[str]:
    private_key = _normalize_key(
        private_api_key
    )

    if private_key is not None:
        return private_key

    return _normalize_key(
        default_api_key
    )