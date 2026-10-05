import logging
import re

from fastapi import HTTPException

from core.config import settings
from core.security import get_safe_key

from models.schemas import ChatRequest

from services.ai_service import AIService
from services.prompt_engine import create_producer_prompt
from services.quota_service import QuotaService
from services.rate_limiter import RateLimiter
from services.safety_service import SafetyService


class ChatService:
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    DEFAULT_ESTIMATED_TOKENS = 2500

    DEFAULT_MAX_COMPLETION_TOKENS = 2048

    PRIVATE_API_MODEL = "openai/gpt-oss-20b"

    # ============================================================
    # RIMAS
    # ============================================================

    DEFAULT_RHYME_COUNT = 5

    MAX_RHYME_COUNT = 30

    RHYME_REPAIR_MAX_COMPLETION_TOKENS = 2048

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        quota_service: QuotaService | None = None,
        rate_limiter: RateLimiter | None = None,
        safety_service: SafetyService | None = None,
    ):
        self.quota_service = (
            quota_service
            or QuotaService()
        )

        self.rate_limiter = (
            rate_limiter
            or RateLimiter()
        )

        self.safety_service = (
            safety_service
            or SafetyService()
        )

        self.logger = logging.getLogger(
            __name__
        )

    # ============================================================
    # PROCESSAR CHAT
    # ============================================================

    async def process(
        self,
        data: ChatRequest,
    ) -> dict:
        # ========================================================
        # 1. RATE LIMIT
        # ========================================================

        await self.rate_limiter.check_rate_limit(
            data.user_id
        )

        # ========================================================
        # 2. VERIFICAR QUOTA
        # ========================================================

        await self._check_quota(
            user_id=data.user_id,
        )

        # ========================================================
        # 3. SANITIZAR ENTRADA
        # ========================================================

        clean_message = (
            self.safety_service
            .sanitize_input(
                data.message
            )
        )

        if not clean_message:
            raise HTTPException(
                status_code=400,
                detail="Mensagem inválida.",
            )

        # ========================================================
        # 4. IDENTIFICAR PEDIDO DE RIMAS
        # ========================================================

        is_rhyme_request = (
            self._is_rhyme_request(
                clean_message
            )
        )

        requested_rhyme_count = (
            self._extract_requested_rhyme_count(
                clean_message
            )
            if is_rhyme_request
            else None
        )

        # ========================================================
        # 5. API KEY
        # ========================================================

        api_key = get_safe_key(
            data.private_api_key,
            settings.GROQ_API_KEY,
        )

        if not api_key:
            raise HTTPException(
                status_code=500,
                detail=(
                    "API Key da Groq "
                    "não configurada."
                ),
            )

        # ========================================================
        # 6. MODELO
        # ========================================================

        selected_model = (
            self._select_model(
                private_api_key=(
                    data.private_api_key
                ),
            )
        )

        # ========================================================
        # 7. PROMPT
        # ========================================================

        prompt = create_producer_prompt(
            context=(
                data.history_context
                or {}
            ),
            rhymes=(
                data.current_list
                or []
            ),
        )

        # ========================================================
        # 8. AI SERVICE
        # ========================================================

        ai_service = AIService(
            api_key=api_key
        )

        try:
            # ====================================================
            # 9. PRIMEIRA CHAMADA
            # ====================================================

            result = (
                await ai_service.get_analysis(
                    system_prompt=prompt,
                    user_message=clean_message,
                    model=selected_model,

                    max_completion_tokens=(
                        self.DEFAULT_MAX_COMPLETION_TOKENS
                    ),

                    json_mode=True,

                    reasoning_effort="low",
                )
            )

            # ====================================================
            # 10. DATA
            # ====================================================

            ai_data = (
                self._extract_ai_data(
                    result
                )
            )

            ai_data = (
                self._normalize_ai_data(
                    ai_data,
                    is_rhyme_request=(
                        is_rhyme_request
                    ),
                    requested_rhyme_count=(
                        requested_rhyme_count
                    ),
                )
            )

            # ====================================================
            # 11. USAGE DA PRIMEIRA CHAMADA
            # ====================================================

            total_usage = (
                self._extract_usage(
                    result
                )
            )

            # ====================================================
            # 12. REPARAR RIMAS INCOMPLETAS
            # ====================================================
            #
            # Exemplo:
            #
            # usuário pede:
            #
            # 10 rimas com pedro
            #
            # IA retorna:
            #
            # certo, aperto, aperto, aperto...
            #
            # Após deduplicar:
            #
            # certo, aperto
            #
            # Como faltam 8, fazemos UMA segunda chamada.
            #
            # ====================================================

            if (
                is_rhyme_request
                and
                requested_rhyme_count is not None
            ):
                current_rhymes = (
                    self._split_rhymes(
                        ai_data.get(
                            "content",
                            "",
                        )
                    )
                )

                if (
                    len(current_rhymes)
                    <
                    requested_rhyme_count
                ):
                    missing_count = (
                        requested_rhyme_count
                        - len(current_rhymes)
                    )

                    self.logger.warning(
                        (
                            "[CHAT] Rimas insuficientes "
                            "após deduplicação | "
                            "requested=%s | "
                            "unique=%s | "
                            "missing=%s"
                        ),
                        requested_rhyme_count,
                        len(current_rhymes),
                        missing_count,
                    )

                    repair_result = (
                        await self._repair_rhymes(
                            ai_service=ai_service,
                            system_prompt=prompt,
                            original_message=(
                                clean_message
                            ),
                            existing_rhymes=(
                                current_rhymes
                            ),
                            requested_count=(
                                requested_rhyme_count
                            ),
                            model=selected_model,
                        )
                    )

                    # =============================================
                    # USAGE DO REPARO
                    # =============================================

                    repair_usage = (
                        self._extract_usage(
                            repair_result
                        )
                    )

                    total_usage = (
                        self._merge_usage(
                            total_usage,
                            repair_usage,
                        )
                    )

                    # =============================================
                    # DATA DO REPARO
                    # =============================================

                    repair_data = (
                        self._extract_ai_data(
                            repair_result
                        )
                    )

                    repair_data = (
                        self._normalize_ai_data(
                            repair_data,
                            is_rhyme_request=True,
                            requested_rhyme_count=None,
                        )
                    )

                    repair_rhymes = (
                        self._split_rhymes(
                            repair_data.get(
                                "content",
                                "",
                            )
                        )
                    )

                    # =============================================
                    # UNIR SEM DUPLICAR
                    # =============================================

                    merged_rhymes = (
                        self._merge_unique_rhymes(
                            current_rhymes,
                            repair_rhymes,
                        )
                    )

                    # =============================================
                    # RESPEITAR QUANTIDADE PEDIDA
                    # =============================================

                    merged_rhymes = (
                        merged_rhymes[
                            :requested_rhyme_count
                        ]
                    )

                    ai_data[
                        "content"
                    ] = ", ".join(
                        merged_rhymes
                    )

            # ====================================================
            # 13. VALIDAR SEGURANÇA
            # ====================================================

            if not (
                self.safety_service
                .is_content_safe(
                    ai_data
                )
            ):
                return (
                    self._build_blocked_response()
                )

            # ====================================================
            # 14. TOKENS REAIS
            # ====================================================

            input_tokens = (
                total_usage[
                    "input_tokens"
                ]
            )

            output_tokens = (
                total_usage[
                    "output_tokens"
                ]
            )

            total_tokens = (
                total_usage[
                    "total_tokens"
                ]
            )

            # ====================================================
            # 15. REGISTRAR QUOTA
            # ====================================================

            quota_status = (
                await self
                .quota_service
                .register_usage_and_get_status(
                    user_id=data.user_id,

                    input_tokens=(
                        input_tokens
                    ),

                    output_tokens=(
                        output_tokens
                    ),
                )
            )

            # ====================================================
            # 16. LOG
            # ====================================================

            self.logger.info(
                (
                    "[CHAT] "
                    "user=%s | "
                    "model=%s | "
                    "rhyme_request=%s | "
                    "input=%s | "
                    "output=%s | "
                    "total=%s | "
                    "monthly=%s"
                ),
                data.user_id,
                selected_model,
                is_rhyme_request,
                input_tokens,
                output_tokens,
                total_tokens,
                quota_status.get(
                    "used_tokens",
                    0,
                ),
            )

            # ====================================================
            # 17. RESPOSTA FINAL
            # ====================================================

            return self._build_response(
                ai_data=ai_data,
                usage=total_usage,
                quota_status=quota_status,
            )

        # ========================================================
        # HTTP EXCEPTION
        # ========================================================

        except HTTPException:
            raise

        # ========================================================
        # VALUE ERROR
        # ========================================================

        except ValueError as error:
            self.logger.warning(
                (
                    "[CHAT SERVICE] "
                    "Resposta inválida da IA: %s"
                ),
                str(error),
            )

            raise HTTPException(
                status_code=502,
                detail=(
                    "A IA não conseguiu gerar "
                    "uma resposta válida. "
                    "Tente novamente."
                ),
            ) from error

        # ========================================================
        # OUTROS ERROS
        # ========================================================

        except Exception as error:
            self.logger.exception(
                (
                    "[CHAT SERVICE] "
                    "Erro crítico."
                )
            )

            raise HTTPException(
                status_code=502,
                detail=(
                    "Falha temporária na "
                    "comunicação com a IA."
                ),
            ) from error

        # ========================================================
        # FECHAR CLIENTE
        # ========================================================

        finally:
            await ai_service.close()

    # ============================================================
    # REPARAR RIMAS
    # ============================================================

    async def _repair_rhymes(
        self,
        *,
        ai_service: AIService,
        system_prompt: str,
        original_message: str,
        existing_rhymes: list[str],
        requested_count: int,
        model: str,
    ) -> dict:
        missing_count = max(
            requested_count
            - len(existing_rhymes),
            0,
        )

        existing_string = (
            ", ".join(
                existing_rhymes
            )
            if existing_rhymes
            else "nenhuma"
        )

        repair_message = (
            f"{original_message}\n\n"
            "CORREÇÃO OBRIGATÓRIA:\n"
            f"O usuário pediu {requested_count} rimas únicas.\n"
            f"Já temos estas opções válidas: {existing_string}.\n"
            f"Faltam {missing_count} opções.\n"
            "Gere somente novas rimas diferentes das já existentes.\n"
            "Não repita nenhuma palavra.\n"
            "Todas devem ser únicas.\n"
            "No campo content, retorne somente as novas palavras "
            "separadas por vírgula e espaço."
        )

        return await (
            ai_service.get_analysis(
                system_prompt=system_prompt,
                user_message=repair_message,
                model=model,

                max_completion_tokens=(
                    self.RHYME_REPAIR_MAX_COMPLETION_TOKENS
                ),

                json_mode=True,

                reasoning_effort="low",
            )
        )

    # ============================================================
    # DETECTAR PEDIDO DE RIMAS
    # ============================================================

    @staticmethod
    def _is_rhyme_request(
        message: str,
    ) -> bool:
        if not isinstance(
            message,
            str,
        ):
            return False

        text = (
            message
            .casefold()
            .strip()
        )

        if not text:
            return False

        patterns = (
            r"\brima\b",
            r"\brimas\b",
            r"\brimar\b",
            r"\brime\b",
            r"\brimando\b",
        )

        return any(
            re.search(
                pattern,
                text,
            )
            is not None
            for pattern
            in patterns
        )

    # ============================================================
    # EXTRAIR QUANTIDADE PEDIDA
    # ============================================================

    @classmethod
    def _extract_requested_rhyme_count(
        cls,
        message: str,
    ) -> int:
        if not isinstance(
            message,
            str,
        ):
            return cls.DEFAULT_RHYME_COUNT

        text = (
            message
            .casefold()
            .strip()
        )

        # ========================================================
        # Exemplos:
        #
        # 10 rimas com pedro
        # me dê 15 rimas
        # quero 8 rimas para amor
        #
        # ========================================================

        match = re.search(
            r"\b(\d{1,3})\s+rimas?\b",
            text,
        )

        if match is None:
            return (
                cls.DEFAULT_RHYME_COUNT
            )

        try:
            amount = int(
                match.group(1)
            )

        except (
            TypeError,
            ValueError,
        ):
            return (
                cls.DEFAULT_RHYME_COUNT
            )

        return max(
            1,
            min(
                amount,
                cls.MAX_RHYME_COUNT,
            ),
        )

    # ============================================================
    # DIVIDIR RIMAS
    # ============================================================

    @classmethod
    def _split_rhymes(
        cls,
        content: str,
    ) -> list[str]:
        if not isinstance(
            content,
            str,
        ):
            return []

        # ========================================================
        # NORMALIZAR QUEBRAS
        # ========================================================

        content = (
            content
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
        # QUEBRA POR:
        #
        # vírgula
        # ponto e vírgula
        # newline
        #
        # ========================================================

        raw_parts = re.split(
            r"[,;\n]+",
            content,
        )

        result: list[str] = []

        seen: set[str] = set()

        for raw_part in raw_parts:
            value = (
                cls._clean_rhyme(
                    raw_part
                )
            )

            if not value:
                continue

            normalized = (
                value.casefold()
            )

            if normalized in seen:
                continue

            seen.add(
                normalized
            )

            result.append(
                value
            )

        return result

    # ============================================================
    # LIMPAR UMA RIMA
    # ============================================================

    @staticmethod
    def _clean_rhyme(
        value: str,
    ) -> str:
        if not isinstance(
            value,
            str,
        ):
            return ""

        value = (
            value.strip()
        )

        if not value:
            return ""

        # ========================================================
        # REMOVE NUMERAÇÃO
        #
        # 1. palavra
        # 2) palavra
        # 3 - palavra
        # ========================================================

        value = re.sub(
            r"^\s*\d+\s*[\.\)\-:]\s*",
            "",
            value,
        )

        # ========================================================
        # REMOVE BULLETS
        # ========================================================

        value = re.sub(
            r"^\s*[-•*]\s*",
            "",
            value,
        )

        # ========================================================
        # REMOVE PREFIXOS QUE ESCAPARAM
        # ========================================================

        value = re.sub(
            (
                r"^\s*"
                r"(rimas?|opções?|palavras?)"
                r"\s*:\s*"
            ),
            "",
            value,
            flags=re.IGNORECASE,
        )

        # ========================================================
        # REMOVE COLCHETES
        # ========================================================

        value = (
            value
            .strip()
            .strip("[]")
            .strip()
        )

        # ========================================================
        # REMOVE ASPAS EXTERNAS
        # ========================================================

        while (
            len(value) >= 2
            and (
                (
                    value.startswith("'")
                    and value.endswith("'")
                )
                or (
                    value.startswith('"')
                    and value.endswith('"')
                )
                or (
                    value.startswith("`")
                    and value.endswith("`")
                )
            )
        ):
            value = (
                value[1:-1]
                .strip()
            )

        # ========================================================
        # LIMPEZA FINAL
        # ========================================================

        value = (
            value
            .strip()
            .strip(",;")
            .strip()
        )

        return value

    # ============================================================
    # UNIR RIMAS SEM REPETIR
    # ============================================================

    @staticmethod
    def _merge_unique_rhymes(
        first: list[str],
        second: list[str],
    ) -> list[str]:
        result: list[str] = []

        seen: set[str] = set()

        for value in (
            list(first)
            + list(second)
        ):
            if not isinstance(
                value,
                str,
            ):
                continue

            clean_value = (
                value.strip()
            )

            if not clean_value:
                continue

            normalized = (
                clean_value.casefold()
            )

            if normalized in seen:
                continue

            seen.add(
                normalized
            )

            result.append(
                clean_value
            )

        return result

    # ============================================================
    # VERIFICAR QUOTA
    # ============================================================

    async def _check_quota(
        self,
        user_id: str,
    ) -> None:
        can_use_ai = (
            await self
            .quota_service
            .check_limit(
                user_id=user_id,

                estimated_tokens=(
                    self.DEFAULT_ESTIMATED_TOKENS
                ),
            )
        )

        if can_use_ai:
            return

        quota_status = (
            await self
            .quota_service
            .get_status(
                user_id
            )
        )

        global_status = (
            quota_status.get(
                "global",
                {},
            )
        )

        # ========================================================
        # LIMITE GLOBAL
        # ========================================================

        if global_status.get(
            "blocked",
            False,
        ):
            raise HTTPException(
                status_code=429,
                detail={
                    "message": (
                        "A capacidade diária "
                        "da IA do Versin "
                        "foi atingida. "
                        "Tente novamente "
                        "mais tarde."
                    ),

                    "reason": (
                        "global_daily_limit"
                    ),

                    "quota": (
                        quota_status
                    ),
                },
            )

        # ========================================================
        # LIMITE MENSAL
        # ========================================================

        raise HTTPException(
            status_code=429,
            detail={
                "message": (
                    "Limite mensal "
                    "de IA atingido."
                ),

                "reason": (
                    "monthly_user_limit"
                ),

                "quota": (
                    quota_status
                ),
            },
        )

    # ============================================================
    # SELECIONAR MODELO
    # ============================================================

    def _select_model(
        self,
        private_api_key: str | None,
    ) -> str:
        if (
            private_api_key
            and private_api_key.strip()
        ):
            return (
                self.PRIVATE_API_MODEL
            )

        selected_model = (
            settings.GROQ_MODEL
        )

        if not selected_model:
            raise HTTPException(
                status_code=500,
                detail=(
                    "Modelo da Groq "
                    "não configurado."
                ),
            )

        return selected_model

    # ============================================================
    # EXTRAIR DATA
    # ============================================================

    @staticmethod
    def _extract_ai_data(
        result: dict,
    ) -> dict:
        if not isinstance(
            result,
            dict,
        ):
            raise ValueError(
                "Resultado da IA inválido."
            )

        data = result.get(
            "data"
        )

        if not isinstance(
            data,
            dict,
        ):
            raise ValueError(
                (
                    "Conteúdo retornado "
                    "pela IA é inválido."
                )
            )

        return data

    # ============================================================
    # NORMALIZAR DATA
    # ============================================================

    @classmethod
    def _normalize_ai_data(
        cls,
        ai_data: dict,
        *,
        is_rhyme_request: bool = False,
        requested_rhyme_count: int | None = None,
    ) -> dict:
        normalized = dict(
            ai_data
        )

        # ========================================================
        # CONTENT
        # ========================================================

        content = normalized.get(
            "content"
        )

        # ========================================================
        # FALLBACK DO AI SERVICE
        # ========================================================

        if not isinstance(
            content,
            str,
        ):
            content = normalized.get(
                "message"
            )

        if not isinstance(
            content,
            str,
        ):
            content = ""

        content = (
            content.strip()
        )

        # ========================================================
        # NORMALIZAR RIMAS
        # ========================================================

        if (
            is_rhyme_request
            and content
        ):
            rhymes = (
                cls._split_rhymes(
                    content
                )
            )

            if (
                requested_rhyme_count
                is not None
            ):
                rhymes = (
                    rhymes[
                        :requested_rhyme_count
                    ]
                )

            content = (
                ", ".join(
                    rhymes
                )
            )

        # ========================================================
        # VAZIO
        # ========================================================

        if not content:
            raise ValueError(
                "A IA retornou conteúdo vazio."
            )

        normalized[
            "content"
        ] = content

        # ========================================================
        # IS ACCEPTABLE
        # ========================================================

        is_acceptable = (
            normalized.get(
                "is_acceptable"
            )
        )

        if isinstance(
            is_acceptable,
            bool,
        ):
            normalized[
                "is_acceptable"
            ] = is_acceptable

        else:
            normalized[
                "is_acceptable"
            ] = True

        # ========================================================
        # IMPACT LEVEL
        # ========================================================

        impact_level = (
            cls._safe_int(
                normalized.get(
                    "impact_level",
                    1,
                )
            )
        )

        normalized[
            "impact_level"
        ] = max(
            1,
            min(
                impact_level,
                5,
            ),
        )

        # ========================================================
        # FEEDBACK
        # ========================================================

        feedback_reason = (
            normalized.get(
                "feedback_reason"
            )
        )

        if not isinstance(
            feedback_reason,
            str,
        ):
            feedback_reason = (
                "Resposta gerada normalmente."
            )

        feedback_reason = (
            feedback_reason.strip()
            or
            "Resposta gerada normalmente."
        )

        normalized[
            "feedback_reason"
        ] = feedback_reason

        return normalized

    # ============================================================
    # EXTRAIR TOKENS
    # ============================================================

    @staticmethod
    def _extract_usage(
        result: dict,
    ) -> dict:
        raw_usage = (
            result.get(
                "usage",
                {},
            )
            if isinstance(
                result,
                dict,
            )
            else {}
        )

        if not isinstance(
            raw_usage,
            dict,
        ):
            raw_usage = {}

        input_tokens = (
            ChatService._safe_int(
                raw_usage.get(
                    "input_tokens",
                    0,
                )
            )
        )

        output_tokens = (
            ChatService._safe_int(
                raw_usage.get(
                    "output_tokens",
                    0,
                )
            )
        )

        total_tokens = (
            ChatService._safe_int(
                raw_usage.get(
                    "total_tokens",
                    (
                        input_tokens
                        + output_tokens
                    ),
                )
            )
        )

        if total_tokens <= 0:
            total_tokens = (
                input_tokens
                + output_tokens
            )

        return {
            "input_tokens": (
                input_tokens
            ),

            "output_tokens": (
                output_tokens
            ),

            "total_tokens": (
                total_tokens
            ),
        }

    # ============================================================
    # SOMAR USAGES
    # ============================================================

    @staticmethod
    def _merge_usage(
        first: dict,
        second: dict,
    ) -> dict:
        input_tokens = (
            ChatService._safe_int(
                first.get(
                    "input_tokens",
                    0,
                )
            )
            +
            ChatService._safe_int(
                second.get(
                    "input_tokens",
                    0,
                )
            )
        )

        output_tokens = (
            ChatService._safe_int(
                first.get(
                    "output_tokens",
                    0,
                )
            )
            +
            ChatService._safe_int(
                second.get(
                    "output_tokens",
                    0,
                )
            )
        )

        total_tokens = (
            input_tokens
            + output_tokens
        )

        return {
            "input_tokens": (
                input_tokens
            ),

            "output_tokens": (
                output_tokens
            ),

            "total_tokens": (
                total_tokens
            ),
        }

    # ============================================================
    # CONVERSÃO SEGURA
    # ============================================================

    @staticmethod
    def _safe_int(
        value,
    ) -> int:
        try:
            return max(
                int(
                    value
                    or 0
                ),
                0,
            )

        except (
            TypeError,
            ValueError,
        ):
            return 0

    # ============================================================
    # RESPOSTA BLOQUEADA
    # ============================================================

    @staticmethod
    def _build_blocked_response() -> dict:
        return {
            "role": "assistant",

            "content": (
                "Não foi possível "
                "processar essa análise."
            ),

            "is_acceptable": False,

            "impact_level": 1,

            "feedback_reason": (
                "Resposta bloqueada "
                "pela camada de segurança."
            ),
        }

    # ============================================================
    # RESPOSTA FINAL
    # ============================================================

    @staticmethod
    def _build_response(
        ai_data: dict,
        usage: dict,
        quota_status: dict,
    ) -> dict:
        # ========================================================
        # CONTENT
        # ========================================================

        content = ai_data.get(
            "content",
            "",
        )

        if not isinstance(
            content,
            str,
        ):
            content = str(
                content
                or ""
            )

        content = (
            content.strip()
        )

        if not content:
            raise ValueError(
                "Conteúdo final vazio."
            )

        # ========================================================
        # IMPACT LEVEL
        # ========================================================

        impact_level = (
            ChatService._safe_int(
                ai_data.get(
                    "impact_level",
                    1,
                )
            )
        )

        impact_level = max(
            1,
            min(
                impact_level,
                5,
            ),
        )

        # ========================================================
        # FEEDBACK
        # ========================================================

        feedback_reason = (
            ai_data.get(
                "feedback_reason",
                "Análise concluída.",
            )
        )

        if not isinstance(
            feedback_reason,
            str,
        ):
            feedback_reason = (
                "Análise concluída."
            )

        feedback_reason = (
            feedback_reason.strip()
            or
            "Análise concluída."
        )

        # ========================================================
        # ACCEPTABLE
        # ========================================================

        is_acceptable = (
            ai_data.get(
                "is_acceptable",
                True,
            )
        )

        if not isinstance(
            is_acceptable,
            bool,
        ):
            is_acceptable = True

        # ========================================================
        # RETORNO
        # ========================================================

        return {
            "role": "assistant",

            "content": content,

            "is_acceptable": (
                is_acceptable
            ),

            "impact_level": (
                impact_level
            ),

            "feedback_reason": (
                feedback_reason
            ),

            "usage": usage,

            "quota": quota_status,
        }

    # ============================================================
    # FECHAR SERVIÇOS
    # ============================================================

    async def close(
        self,
    ) -> None:
        await self.quota_service.close()

        await self.rate_limiter.close()