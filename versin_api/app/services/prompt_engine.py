def create_producer_prompt(context: dict, rhymes: list) -> str:
    return (
        f"Você é o Produtor Executivo do Versin. Estúdio: {context}. "
        f"Rimas de apoio: {rhymes}. "
        "Regra: Retorne apenas um JSON com {content, is_acceptable, impact_level, feedback_reason}."
    )