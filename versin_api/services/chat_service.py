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

    DEFAULT_ESTIMATED_TOKENS = 700

    PRIVATE_API_MODEL = "llama-3.3-70b-versatile"

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

            result = await ai_service.get_analysis(
                system_prompt=prompt,
                user_message=clean_message,
                model=selected_model,
            )

            # ====================================================
            # 9. NORMALIZAR RESULTADO
            # ====================================================

            ai_data = self._extract_ai_data(
                result
            )

            usage = self._extract_usage(
                result
            )

            # ====================================================
            # 10. VALIDAR RESPOSTA
            # ====================================================

            if not self.safety_service.is_content_safe(
                ai_data
            ):
                return {
                    "role":
                        "assistant",

                    "content":
                        (
                            "Não foi possível "
                            "processar essa análise."
                        ),

                    "is_acceptable":
                        False,

                    "impact_level":
                        1,

                    "feedback_reason":
                        (
                            "Resposta bloqueada "
                            "pela camada de segurança."
                        ),
                }

            # ====================================================
            # 11. TOKENS REAIS
            # ====================================================

            input_tokens = usage[
                "input_tokens"
            ]

            output_tokens = usage[
                "output_tokens"
            ]

            total_tokens = usage[
                "total_tokens"
            ]

            # ====================================================
            # 12. REGISTRAR QUOTA
            # ====================================================

            quota_status = (
                await self
                .quota_service
                .register_usage_and_get_status(
                    user_id=data.user_id,
                    input_tokens=input_tokens,
                    output_tokens=output_tokens,
                )
            )

            # ====================================================
            # 13. DEBUG
            # ====================================================

            print(
                (
                    "[CHAT] "
                    f"user={data.user_id} | "
                    f"model={selected_model} | "
                    f"input={input_tokens} | "
                    f"output={output_tokens} | "
                    f"total={total_tokens} | "
                    f"monthly="
                    f"{quota_status.get('used_tokens', 0)}"
                )
            )

            # ====================================================
            # 14. RESPOSTA FINAL
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
        # OUTROS ERROS
        # ========================================================

        except Exception as error:
            print(
                (
                    "[CHAT SERVICE] "
                    "Erro crítico: "
                    f"{str(error)}"
                )
            )

            raise HTTPException(
                status_code=500,
                detail=(
                    "Falha na conexão "
                    "com a IA."
                ),
            )

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
                    "message":
                        (
                            "A capacidade diária "
                            "da IA do Versin "
                            "foi atingida. "
                            "Tente novamente "
                            "mais tarde."
                        ),

                    "reason":
                        "global_daily_limit",

                    "quota":
                        quota_status,
                },
            )

        # ========================================================
        # LIMITE MENSAL DO USUÁRIO
        # ========================================================

        raise HTTPException(
            status_code=429,
            detail={
                "message":
                    (
                        "Limite mensal "
                        "de IA atingido."
                    ),

                "reason":
                    "monthly_user_limit",

                "quota":
                    quota_status,
            },
        )

    # ============================================================
    # SELECIONAR MODELO
    # ============================================================

    def _select_model(
        self,
        private_api_key: str | None,
    ) -> str:
        # ========================================================
        # API PRIVADA
        # ========================================================
        #
        # Mantemos o comportamento que você já tinha:
        #
        # API privada:
        # llama-3.3-70b-versatile
        #
        # API padrão do Versin:
        # settings.GROQ_MODEL
        #
        # ========================================================

        if (
            private_api_key
            and private_api_key.strip()
        ):
            return self.PRIVATE_API_MODEL

        return settings.GROQ_MODEL

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
                "Conteúdo retornado "
                "pela IA é inválido."
            )

        return data

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
            "input_tokens":
                input_tokens,

            "output_tokens":
                output_tokens,

            "total_tokens":
                total_tokens,
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

        content = (
            ai_data.get(
                "content"
            )
        )

        if not isinstance(
            content,
            str,
        ):
            content = (
                "Nenhum feedback "
                "disponível."
            )

        content = (
            content.strip()
            or
            "Nenhum feedback disponível."
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
                "feedback_reason"
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
        # RETORNO
        # ========================================================

        return {
            "role":
                "assistant",

            "content":
                content,

            "is_acceptable":
                bool(
                    ai_data.get(
                        "is_acceptable",
                        False,
                    )
                ),

            "impact_level":
                impact_level,

            "feedback_reason":
                feedback_reason,

            # =================================================
            # USO DA REQUISIÇÃO
            # =================================================

            "usage":
                usage,

            # =================================================
            # QUOTA DO USUÁRIO
            # =================================================
            #
            # O RhymesController já foi preparado para
            # interpretar este campo.
            #
            # =================================================

            "quota":
                quota_status,
        }

    # ============================================================
    # FECHAR SERVIÇOS
    # ============================================================

    async def close(
        self,
    ) -> None:
        await self.quota_service.close()

        await self.rate_limiter.close()