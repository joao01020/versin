import logging

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
        # 4. API KEY
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
        # 5. MODELO
        # ========================================================

        selected_model = (
            self._select_model(
                private_api_key=(
                    data.private_api_key
                ),
            )
        )

        # ========================================================
        # 6. PROMPT
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
        # 7. AI SERVICE
        # ========================================================

        ai_service = AIService(
            api_key=api_key
        )

        try:
            # ====================================================
            # 8. CHAMADA PARA GROQ
            # ====================================================

            result = (
                await ai_service.get_analysis(
                    system_prompt=prompt,
                    user_message=clean_message,
                    model=selected_model,

                    max_completion_tokens=(
                        self.DEFAULT_MAX_COMPLETION_TOKENS
                    ),

                    # =============================================
                    # O prompt do Versin trabalha com:
                    #
                    # content
                    # is_acceptable
                    # impact_level
                    # feedback_reason
                    #
                    # Portanto tentamos JSON primeiro.
                    #
                    # O AIService possui fallback automático
                    # para texto caso a Groq falhe no JSON.
                    # =============================================

                    json_mode=True,

                    # =============================================
                    # Evita que GPT-OSS consuma todos os tokens
                    # apenas pensando.
                    # =============================================

                    reasoning_effort="low",
                )
            )

            # ====================================================
            # 9. NORMALIZAR RESULTADO DA IA
            # ====================================================

            ai_data = (
                self._extract_ai_data(
                    result
                )
            )

            ai_data = (
                self._normalize_ai_data(
                    ai_data
                )
            )

            # ====================================================
            # 10. USAGE
            # ====================================================

            usage = (
                self._extract_usage(
                    result
                )
            )

            # ====================================================
            # 11. VALIDAR SEGURANÇA
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
            # 12. TOKENS
            # ====================================================

            input_tokens = (
                usage[
                    "input_tokens"
                ]
            )

            output_tokens = (
                usage[
                    "output_tokens"
                ]
            )

            total_tokens = (
                usage[
                    "total_tokens"
                ]
            )

            # ====================================================
            # 13. REGISTRAR QUOTA
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
            # 14. LOG
            # ====================================================

            self.logger.info(
                (
                    "[CHAT] "
                    "user=%s | "
                    "model=%s | "
                    "input=%s | "
                    "output=%s | "
                    "total=%s | "
                    "monthly=%s"
                ),
                data.user_id,
                selected_model,
                input_tokens,
                output_tokens,
                total_tokens,
                quota_status.get(
                    "used_tokens",
                    0,
                ),
            )

            # ====================================================
            # 15. RESPOSTA FINAL
            # ====================================================

            return self._build_response(
                ai_data=ai_data,
                usage=usage,
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

        finally:
            # ====================================================
            # FECHAR CLIENTE GROQ
            # ====================================================

            await ai_service.close()

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

                    "quota": quota_status,
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

                "quota": quota_status,
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
    # EXTRAIR DATA DA IA
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
    # NORMALIZAR DATA DA IA
    # ============================================================

    @staticmethod
    def _normalize_ai_data(
        ai_data: dict,
    ) -> dict:
        normalized = dict(
            ai_data
        )

        # ========================================================
        # CONTENT
        # ========================================================
        #
        # Em JSON mode normalmente vem:
        #
        # {
        #   "content": "..."
        # }
        #
        # No fallback de texto do AIService vem:
        #
        # {
        #   "message": "..."
        # }
        #
        # Aqui aceitamos os dois.
        #
        # ========================================================

        content = normalized.get(
            "content"
        )

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

        content = content.strip()

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

        is_acceptable = normalized.get(
            "is_acceptable"
        )

        if isinstance(
            is_acceptable,
            bool,
        ):
            normalized[
                "is_acceptable"
            ] = is_acceptable

        else:
            # Se houve fallback para texto normal,
            # consideramos aceitável até que o
            # SafetyService faça sua própria validação.

            normalized[
                "is_acceptable"
            ] = True

        # ========================================================
        # IMPACT LEVEL
        # ========================================================

        impact_level = (
            ChatService._safe_int(
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
        # FEEDBACK REASON
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
            "role": (
                "assistant"
            ),

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
            ""
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
            "role": (
                "assistant"
            ),

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

            # ====================================================
            # TOKENS DESTA REQUISIÇÃO
            # ====================================================

            "usage": usage,

            # ====================================================
            # QUOTA ATUAL
            # ====================================================

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