import logging
import re

from typing import Any


class SafetyService:
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    MAX_INPUT_LENGTH = 12_000

    MAX_OUTPUT_LENGTH = 50_000

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
    ):
        self.logger = logging.getLogger(
            __name__
        )

    # ============================================================
    # SANITIZAR ENTRADA
    # ============================================================

    def sanitize_input(
        self,
        user_message: str,
    ) -> str:
        if not isinstance(
            user_message,
            str,
        ):
            return ""

        # ========================================================
        # NORMALIZAR QUEBRAS DE LINHA
        # ========================================================

        sanitized = (
            user_message
            .replace(
                "\r\n",
                "\n",
            )
            .replace(
                "\r",
                "\n",
            )
        )

        # ========================================================
        # REMOVER CARACTERES DE CONTROLE
        # ========================================================
        #
        # Preservamos:
        #
        # \n
        # \t
        # {}
        # []
        # aspas
        # pontuação
        # emojis
        # acentos
        #
        # ========================================================

        sanitized = re.sub(
            r"[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]",
            "",
            sanitized,
        )

        # ========================================================
        # EVITAR EXCESSO DE LINHAS VAZIAS
        # ========================================================

        sanitized = re.sub(
            r"\n{4,}",
            "\n\n\n",
            sanitized,
        )

        # ========================================================
        # LIMITAR TAMANHO
        # ========================================================

        sanitized = sanitized[
            :self.MAX_INPUT_LENGTH
        ]

        return sanitized.strip()

    # ============================================================
    # VALIDAR ENTRADA
    # ============================================================

    def validate_input(
        self,
        user_message: str,
    ) -> bool:
        if not isinstance(
            user_message,
            str,
        ):
            return False

        clean_message = (
            user_message.strip()
        )

        if not clean_message:
            return False

        if (
            len(user_message)
            >
            self.MAX_INPUT_LENGTH
        ):
            return False

        return True

    # ============================================================
    # DETECTAR POSSÍVEL PROMPT INJECTION
    # ============================================================
    #
    # Não bloqueia automaticamente.
    #
    # Serve apenas como sinal para logs/monitoramento.
    #
    # ============================================================

    def detect_prompt_injection(
        self,
        user_message: str,
    ) -> bool:
        if not isinstance(
            user_message,
            str,
        ):
            return False

        text = (
            user_message
            .casefold()
            .strip()
        )

        if not text:
            return False

        suspicious_patterns = (
            "ignore previous instructions",
            "ignore all previous instructions",
            "ignore suas instruções",
            "ignore as instruções anteriores",
            "ignore todas as instruções anteriores",
            "revele seu prompt",
            "mostre seu prompt",
            "mostre o prompt do sistema",
            "mostre as instruções do sistema",
            "system prompt",
            "developer message",
        )

        detected = any(
            pattern in text
            for pattern
            in suspicious_patterns
        )

        if detected:
            self.logger.warning(
                (
                    "[SAFETY] Possível "
                    "prompt injection detectado."
                )
            )

        return detected

    # ============================================================
    # VALIDAR RESPOSTA DA IA
    # ============================================================

    def is_response_valid(
        self,
        ai_response: Any,
    ) -> bool:
        # ========================================================
        # DEVE SER DICT
        # ========================================================

        if not isinstance(
            ai_response,
            dict,
        ):
            self.logger.warning(
                (
                    "[SAFETY] Resposta rejeitada: "
                    "não é um dicionário."
                )
            )

            return False

        # ========================================================
        # CONTENT
        # ========================================================

        content = (
            ai_response.get(
                "content"
            )
        )

        if not isinstance(
            content,
            str,
        ):
            self.logger.warning(
                (
                    "[SAFETY] Resposta rejeitada: "
                    "content não é string."
                )
            )

            return False

        content = (
            content.strip()
        )

        if not content:
            self.logger.warning(
                (
                    "[SAFETY] Resposta rejeitada: "
                    "content está vazio."
                )
            )

            return False

        # ========================================================
        # LIMITE DE SAÍDA
        # ========================================================

        if (
            len(content)
            >
            self.MAX_OUTPUT_LENGTH
        ):
            self.logger.warning(
                (
                    "[SAFETY] Resposta rejeitada: "
                    "content excedeu o limite."
                )
            )

            return False

        # ========================================================
        # IS ACCEPTABLE
        # ========================================================

        is_acceptable = (
            ai_response.get(
                "is_acceptable"
            )
        )

        if (
            is_acceptable is not None
            and
            not isinstance(
                is_acceptable,
                bool,
            )
        ):
            self.logger.warning(
                (
                    "[SAFETY] Aviso: "
                    "is_acceptable não é boolean."
                )
            )

        # ========================================================
        # IMPACT LEVEL
        # ========================================================

        impact_level = (
            ai_response.get(
                "impact_level"
            )
        )

        if impact_level is not None:
            try:
                normalized_impact = (
                    int(
                        impact_level
                    )
                )

                if not (
                    1
                    <= normalized_impact
                    <= 5
                ):
                    self.logger.warning(
                        (
                            "[SAFETY] Aviso: "
                            "impact_level fora "
                            "da faixa 1-5."
                        )
                    )

            except (
                TypeError,
                ValueError,
            ):
                self.logger.warning(
                    (
                        "[SAFETY] Aviso: "
                        "impact_level inválido."
                    )
                )

        # ========================================================
        # FEEDBACK REASON
        # ========================================================

        feedback_reason = (
            ai_response.get(
                "feedback_reason"
            )
        )

        if (
            feedback_reason is not None
            and
            not isinstance(
                feedback_reason,
                str,
            )
        ):
            self.logger.warning(
                (
                    "[SAFETY] Aviso: "
                    "feedback_reason não "
                    "é string."
                )
            )

        # ========================================================
        # RESPOSTA VÁLIDA
        # ========================================================

        return True

    # ============================================================
    # COMPATIBILIDADE COM CHAT SERVICE
    # ============================================================

    def is_content_safe(
        self,
        ai_response: Any,
    ) -> bool:
        return self.is_response_valid(
            ai_response
        )