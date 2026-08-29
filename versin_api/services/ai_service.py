import json
import logging

from groq import AsyncGroq
from groq import BadRequestError

from core.config import settings


class AIService:
    # ============================================================
    # CONFIGURAÇÃO
    # ============================================================

    DEFAULT_MAX_COMPLETION_TOKENS = 500
    DEFAULT_TEMPERATURE = 0.6

    # ============================================================
    # CONSTRUTOR
    # ============================================================

    def __init__(
        self,
        api_key: str | None = None,
    ):
        final_api_key = (
            api_key
            or settings.GROQ_API_KEY
        )

        if not final_api_key:
            raise ValueError(
                "GROQ_API_KEY não configurada."
            )

        self.client = AsyncGroq(
            api_key=final_api_key,
        )

        self.logger = logging.getLogger(
            __name__,
        )

    # ============================================================
    # ANÁLISE COM IA
    # ============================================================

    async def get_analysis(
        self,
        system_prompt: str,
        user_message: str,
        model: str | None = None,
        max_completion_tokens: int = DEFAULT_MAX_COMPLETION_TOKENS,
        temperature: float = DEFAULT_TEMPERATURE,
        json_mode: bool = False,
    ) -> dict:
        # ========================================================
        # MODELO
        # ========================================================

        selected_model = (
            model
            or settings.GROQ_MODEL
        )

        # ========================================================
        # VALIDAR SYSTEM PROMPT
        # ========================================================

        normalized_system_prompt = (
            system_prompt.strip()
        )

        if not normalized_system_prompt:
            raise ValueError(
                "system_prompt não pode ser vazio."
            )

        # ========================================================
        # VALIDAR MENSAGEM
        # ========================================================

        normalized_user_message = (
            user_message.strip()
        )

        if not normalized_user_message:
            raise ValueError(
                "user_message não pode ser vazio."
            )

        # ========================================================
        # LIMITE DE ENTRADA
        # ========================================================

        if (
            len(normalized_user_message)
            >
            settings.AI_MAX_INPUT_LENGTH
        ):
            raise ValueError(
                "Mensagem ultrapassa o tamanho "
                "máximo permitido."
            )

        # ========================================================
        # LIMITE DE SAÍDA
        # ========================================================

        max_completion_tokens = max(
            1,
            int(max_completion_tokens),
        )

        # ========================================================
        # TEMPERATURA
        # ========================================================

        temperature = max(
            0.0,
            min(
                float(temperature),
                2.0,
            ),
        )

        # ========================================================
        # MENSAGENS
        # ========================================================

        messages = [
            {
                "role": "system",
                "content": normalized_system_prompt,
            },
            {
                "role": "user",
                "content": normalized_user_message,
            },
        ]

        # ========================================================
        # REQUEST BASE
        # ========================================================

        request_data = {
            "model": selected_model,
            "messages": messages,
            "max_completion_tokens": (
                max_completion_tokens
            ),
            "temperature": temperature,
            "stream": False,
        }

        # ========================================================
        # JSON MODE OPCIONAL
        # ========================================================

        if json_mode:
            request_data["response_format"] = {
                "type": "json_object",
            }

        try:
            # ====================================================
            # CHAMADA PARA GROQ
            # ====================================================

            try:
                response = (
                    await self.client
                    .chat
                    .completions
                    .create(
                        **request_data
                    )
                )

            except BadRequestError as error:
                error_text = str(error)

                # =================================================
                # FALLBACK PARA ERRO DE JSON DA GROQ
                # =================================================

                if (
                    json_mode
                    and
                    "json_validate_failed"
                    in error_text
                ):
                    self.logger.warning(
                        (
                            "Groq falhou ao validar JSON. "
                            "Tentando novamente sem JSON mode."
                        )
                    )

                    fallback_request = dict(
                        request_data
                    )

                    fallback_request.pop(
                        "response_format",
                        None,
                    )

                    response = (
                        await self.client
                        .chat
                        .completions
                        .create(
                            **fallback_request
                        )
                    )

                    json_mode = False

                else:
                    raise

            # ====================================================
            # VALIDAR CHOICES
            # ====================================================

            if not response.choices:
                raise ValueError(
                    "A Groq respondeu sem opções."
                )

            # ====================================================
            # CONTEÚDO
            # ====================================================

            content = (
                response
                .choices[0]
                .message
                .content
            )

            if content is None:
                raise ValueError(
                    "A IA respondeu sem conteúdo."
                )

            content = content.strip()

            if not content:
                raise ValueError(
                    "A IA respondeu com conteúdo vazio."
                )

            # ====================================================
            # CONVERTER RESPOSTA
            # ====================================================

            if json_mode:
                try:
                    data = json.loads(
                        content
                    )

                except json.JSONDecodeError:
                    self.logger.warning(
                        (
                            "Resposta não era JSON válido. "
                            "Retornando como texto."
                        )
                    )

                    data = {
                        "message": content,
                    }

            else:
                data = {
                    "message": content,
                }

            # ====================================================
            # GARANTIR DICT
            # ====================================================

            if not isinstance(
                data,
                dict,
            ):
                data = {
                    "message": str(data),
                }

            # ====================================================
            # USO DE TOKENS
            # ====================================================

            input_tokens = 0
            output_tokens = 0
            total_tokens = 0

            usage = getattr(
                response,
                "usage",
                None,
            )

            if usage is not None:
                input_tokens = self._safe_int(
                    getattr(
                        usage,
                        "prompt_tokens",
                        0,
                    )
                )

                output_tokens = self._safe_int(
                    getattr(
                        usage,
                        "completion_tokens",
                        0,
                    )
                )

                total_tokens = self._safe_int(
                    getattr(
                        usage,
                        "total_tokens",
                        input_tokens
                        + output_tokens,
                    )
                )

            # ====================================================
            # FALLBACK DE TOKENS
            # ====================================================

            if total_tokens <= 0:
                total_tokens = (
                    input_tokens
                    + output_tokens
                )

            # ====================================================
            # METADADOS
            # ====================================================

            response_model = (
                getattr(
                    response,
                    "model",
                    selected_model,
                )
                or selected_model
            )

            response_id = getattr(
                response,
                "id",
                None,
            )

            system_fingerprint = getattr(
                response,
                "system_fingerprint",
                None,
            )

            # ====================================================
            # LOG
            # ====================================================

            self.logger.info(
                (
                    "IA concluída | "
                    "model=%s | "
                    "input=%s | "
                    "output=%s | "
                    "total=%s"
                ),
                response_model,
                input_tokens,
                output_tokens,
                total_tokens,
            )

            # ====================================================
            # RETORNO
            # ====================================================

            return {
                "data": data,

                "usage": {
                    "input_tokens": (
                        input_tokens
                    ),
                    "output_tokens": (
                        output_tokens
                    ),
                    "total_tokens": (
                        total_tokens
                    ),
                },

                "meta": {
                    "model": (
                        response_model
                    ),
                    "response_id": (
                        response_id
                    ),
                    "system_fingerprint": (
                        system_fingerprint
                    ),
                },
            }

        # ========================================================
        # ERRO DE VALIDAÇÃO
        # ========================================================

        except ValueError:
            raise

        # ========================================================
        # ERRO DA GROQ / REDE / OUTROS
        # ========================================================

        except Exception as error:
            self.logger.exception(
                "Erro na chamada da Groq."
            )

            print(
                (
                    "--- ERRO NA CHAMADA "
                    "DA IA: "
                    f"{str(error)} ---"
                )
            )

            raise

    # ============================================================
    # CONVERSÃO SEGURA PARA INT
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
    # FECHAR CLIENTE
    # ============================================================

    async def close(
        self,
    ) -> None:
        try:
            await self.client.close()

        except Exception as error:
            self.logger.warning(
                (
                    "Erro ao fechar "
                    "cliente Groq: %s"
                ),
                error,
            )