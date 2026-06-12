class SafetyService:
    def sanitize_input(self, user_message: str) -> str:
        # Remove caracteres de controle perigosos ou tentativas de escape
        sanitized = user_message.replace("{", "").replace("}", "").replace(";", "")
        return sanitized[:1000]  # Limita o tamanho para evitar ataques de estouro de tokens

    def is_content_safe(self, ai_response: dict) -> bool:
        # Exemplo: Se o conteúdo contiver palavras bloqueadas, rejeitamos
        blocked_words = ["hack", "bomba", "ilícito"]
        content = ai_response.get("content", "").lower()
        
        for word in blocked_words:
            if word in content:
                return False
        return True