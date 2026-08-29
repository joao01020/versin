from typing import Optional


# ============================================================
# CONFIGURAÇÃO
# ============================================================

MAX_API_KEY_LENGTH = 512


# ============================================================
# NORMALIZAR CHAVE
# ============================================================

def _normalize_key(
    api_key: Optional[str],
) -> Optional[str]:
    # ========================================================
    # AUSENTE
    # ========================================================

    if api_key is None:
        return None

    # ========================================================
    # TIPO
    # ========================================================

    if not isinstance(
        api_key,
        str,
    ):
        return None

    # ========================================================
    # NORMALIZAR
    # ========================================================

    normalized = (
        api_key.strip()
    )

    if not normalized:
        return None

    # ========================================================
    # LIMITE DEFENSIVO
    # ========================================================

    if (
        len(normalized)
        >
        MAX_API_KEY_LENGTH
    ):
        return None

    # ========================================================
    # EVITAR QUEBRA DE LINHA
    # ========================================================

    if (
        "\n" in normalized
        or "\r" in normalized
    ):
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
    # ========================================================
    # API PRIVADA
    # ========================================================

    private_key = (
        _normalize_key(
            private_api_key
        )
    )

    if private_key is not None:
        return private_key

    # ========================================================
    # API PADRÃO
    # ========================================================

    return _normalize_key(
        default_api_key
    )