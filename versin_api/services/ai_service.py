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

    EMPTY_RESPONSE_RETRY_MULTIPLIER = 2
    EMPTY_RESPONSE_RETRY_MIN_TOKENS = 1000
    EMPTY_RESPONSE_RETRY_MAX_TOKENS = 2000

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
        selected_model = (
            model
            or settings.GROQ_MODEL
        )

        if not selected_model:
            raise ValueError(
                "Modelo da Groq não configurado."
            )

        normalized_system_prompt = (
            system_prompt.strip()
        )

        if not normalized_system_prompt:
            raise ValueError(
                "system_prompt não pode ser vazio."
            )

        normalized_user_message = (
            user_message.strip()
        )

        if not normalized_user_message:
            raise ValueError(
                "user_message não pode ser vazio."
            )

        if (
            len(normalized_user_message)
            >
            settings.AI_MAX_INPUT_LENGTH
        ):
            raise ValueError(
                "Mensagem ultrapassa o tamanho "
                "máximo permitido."
            )

        max_completion_tokens = max(
            1,
            int(max_completion_tokens),
        )

        temperature = max(
            0.0,
            min(
                float(temperature),
                2.0,
            ),
        )

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

        request_data = {
            "model": selected_model,
            "messages": messages,
            "max_completion_tokens": (
                max_completion_tokens
            ),
            "temperature": temperature,
            "stream": False,
        }

        if json_mode:
            request_data["response_format"] = {
                "type": "json_object",
            }

        try:
            response, used_json_mode = (
                await self._create_completion(
                    request_data=request_data,
                    json_mode=json_mode,
                )
            )

            content = self._extract_content(
                response=response,
            )

            if not content:
                self._log_empty_response(
                    response=response,
                    selected_model=selected_model,
                    attempt=1,
                )

                retry_request = dict(
                    request_data
                )

                retry_request.pop(
                    "response_format",
                    None,
                )

                retry_tokens = max(
                    max_completion_tokens
                    * self.EMPTY_RESPONSE_RETRY_MULTIPLIER,
                    self.EMPTY_RESPONSE_RETRY_MIN_TOKENS,
                )

                retry_tokens = min(
                    retry_tokens,
                    self.EMPTY_RESPONSE_RETRY_MAX_TOKENS,
                )

                retry_request[
                    "max_completion_tokens"
                ] = retry_tokens

                self.logger.warning(
                    (
                        "Groq retornou conteúdo vazio. "
                        "Tentando novamente | "
                        "model=%s | "
                        "tokens=%s"
                    ),
                    selected_model,
                    retry_tokens,
                )

                response, _ = (
                    await self._create_completion(
                        request_data=retry_request,
                        json_mode=False,
                    )
                )

                used_json_mode = False

                content = self._extract_content(
                    response=response,
                )

                if not content:
                    self._log_empty_response(
                        response=response,
                        selected_model=selected_model,
                        attempt=2,
                    )

                    raise ValueError(
                        "A Groq respondeu com conteúdo vazio "
                        "mesmo após uma nova tentativa."
                    )

            if used_json_mode:
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

            if not isinstance(
                data,
                dict,
            ):
                data = {
                    "message": str(data),
                }

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
                        input_tokens + output_tokens,
                    )
                )

            if total_tokens <= 0:
                total_tokens = (
                    input_tokens
                    + output_tokens
                )

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

            finish_reason = self._finish_reason(
                response
            )

            self.logger.info(
                (
                    "IA concluída | "
                    "model=%s | "
                    "finish_reason=%s | "
                    "input=%s | "
                    "output=%s | "
                    "total=%s"
                ),
                response_model,
                finish_reason,
                input_tokens,
                output_tokens,
                total_tokens,
            )

            return {
                "data": data,
                "usage": {
                    "input_tokens": input_tokens,
                    "output_tokens": output_tokens,
                    "total_tokens": total_tokens,
                },
                "meta": {
                    "model": response_model,
                    "response_id": response_id,
                    "system_fingerprint": system_fingerprint,
                    "finish_reason": finish_reason,
                },
            }

        except ValueError:
            raise

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
    # CRIAR COMPLETION
    # ============================================================

    async def _create_completion(
        self,
        request_data: dict,
        json_mode: bool,
    ):
        try:
            response = (
                await self.client
                .chat
                .completions
                .create(
                    **request_data
                )
            )

            return (
                response,
                json_mode,
            )

        except BadRequestError as error:
            error_text = str(
                error
            )

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

                return (
                    response,
                    False,
                )

            raise

    # ============================================================
    # EXTRAIR CONTEÚDO
    # ============================================================

    def _extract_content(
        self,
        response,
    ) -> str:
        choices = getattr(
            response,
            "choices",
            None,
        )

        if not choices:
            raise ValueError(
                "A Groq respondeu sem opções."
            )

        message = getattr(
            choices[0],
            "message",
            None,
        )

        if message is None:
            raise ValueError(
                "A Groq respondeu sem mensagem."
            )

        content = getattr(
            message,
            "content",
            None,
        )

        if content is None:
            return ""

        if not isinstance(
            content,
            str,
        ):
            content = str(
                content
            )

        return content.strip()

    # ============================================================
    # LOG DE RESPOSTA VAZIA
    # ============================================================

    def _log_empty_response(
        self,
        response,
        selected_model: str,
        attempt: int,
    ) -> None:
        choices = getattr(
            response,
            "choices",
            None,
        )

        choice = (
            choices[0]
            if choices
            else None
        )

        message = getattr(
            choice,
            "message",
            None,
        )

        finish_reason = getattr(
            choice,
            "finish_reason",
            None,
        )

        usage = getattr(
            response,
            "usage",
            None,
        )

        prompt_tokens = self._safe_int(
            getattr(
                usage,
                "prompt_tokens",
                0,
            )
            if usage is not None
            else 0
        )

        completion_tokens = self._safe_int(
            getattr(
                usage,
                "completion_tokens",
                0,
            )
            if usage is not None
            else 0
        )

        total_tokens = self._safe_int(
            getattr(
                usage,
                "total_tokens",
                0,
            )
            if usage is not None
            else 0
        )

        tool_calls = (
            getattr(
                message,
                "tool_calls",
                None,
            )
            if message is not None
            else None
        )

        refusal = (
            getattr(
                message,
                "refusal",
                None,
            )
            if message is not None
            else None
        )

        self.logger.warning(
            (
                "Resposta vazia da Groq | "
                "attempt=%s | "
                "model=%s | "
                "finish_reason=%s | "
                "prompt_tokens=%s | "
                "completion_tokens=%s | "
                "total_tokens=%s | "
                "tool_calls=%r | "
                "refusal=%r | "
                "message=%r"
            ),
            attempt,
            selected_model,
            finish_reason,
            prompt_tokens,
            completion_tokens,
            total_tokens,
            tool_calls,
            refusal,
            message,
        )

    # ============================================================
    # FINISH REASON
    # ============================================================

    @staticmethod
    def _finish_reason(
        response,
    ):
        choices = getattr(
            response,
            "choices",
            None,
        )

        if not choices:
            return None

        return getattr(
            choices[0],
            "finish_reason",
            None,
        )

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
