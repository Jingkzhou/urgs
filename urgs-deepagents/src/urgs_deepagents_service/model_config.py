from dataclasses import dataclass
from typing import Any

import httpx
from fastapi import HTTPException
from langchain_core.messages import AIMessage, AIMessageChunk
from langchain_openai import ChatOpenAI

from urgs_deepagents_service.config import Settings
from urgs_deepagents_service.sse import sanitize_text


@dataclass(frozen=True)
class AiApiConfig:
    provider: str
    model: str
    endpoint: str
    api_key: str
    max_tokens: int | None
    temperature: float | None


class ReasoningContentChatOpenAI(ChatOpenAI):
    """Preserve OpenAI-compatible reasoning_content across tool-call rounds.

    DeepSeek thinking mode requires the assistant's reasoning_content to be
    passed back unchanged with its tool_calls. langchain-openai currently drops
    this provider extension when converting chat-completion chunks and messages.
    """

    def _convert_chunk_to_generation_chunk(
        self,
        chunk: dict[str, Any],
        default_chunk_class: type,
        base_generation_info: dict[str, Any] | None,
    ) -> Any:
        generation = super()._convert_chunk_to_generation_chunk(
            chunk, default_chunk_class, base_generation_info
        )
        choices = chunk.get("choices") or chunk.get("chunk", {}).get("choices") or []
        delta = choices[0].get("delta") if choices else None
        reasoning_content = delta.get("reasoning_content") if isinstance(delta, dict) else None
        if (
            generation is not None
            and reasoning_content is not None
            and isinstance(generation.message, AIMessageChunk)
        ):
            generation.message.additional_kwargs["reasoning_content"] = reasoning_content
        return generation

    def _create_chat_result(
        self,
        response: dict[str, Any] | Any,
        generation_info: dict[str, Any] | None = None,
    ) -> Any:
        result = super()._create_chat_result(response, generation_info)
        response_dict = response if isinstance(response, dict) else response.model_dump()
        choices = response_dict.get("choices") or []
        for generation, choice in zip(result.generations, choices, strict=False):
            message = choice.get("message") or {}
            reasoning_content = message.get("reasoning_content")
            if reasoning_content is not None and isinstance(generation.message, AIMessage):
                generation.message.additional_kwargs["reasoning_content"] = reasoning_content
        return result

    def _get_request_payload(
        self,
        input_: Any,
        *,
        stop: list[str] | None = None,
        **kwargs: Any,
    ) -> dict[str, Any]:
        messages = self._convert_input(input_).to_messages()
        payload = super()._get_request_payload(input_, stop=stop, **kwargs)
        outgoing_messages = payload.get("messages")
        if not isinstance(outgoing_messages, list):
            return payload
        for source, outgoing in zip(messages, outgoing_messages, strict=False):
            if not isinstance(source, AIMessage) or not isinstance(outgoing, dict):
                continue
            reasoning_content = source.additional_kwargs.get("reasoning_content")
            if reasoning_content is not None:
                outgoing["reasoning_content"] = reasoning_content
        return payload


def _strip_chat_completions_suffix(endpoint: str) -> str:
    normalized = endpoint.rstrip("/")
    suffix = "/chat/completions"
    if normalized.endswith(suffix):
        return normalized[: -len(suffix)]
    return normalized


def _parse_default_config(payload: dict[str, Any] | None) -> AiApiConfig:
    if not payload:
        raise HTTPException(status_code=502, detail="未配置默认 AI API，请在系统管理中配置")

    model = str(payload.get("model") or "").strip()
    endpoint = str(payload.get("endpoint") or "").strip()
    api_key = str(payload.get("apiKey") or "").strip()
    if not model or not endpoint or not api_key:
        raise HTTPException(
            status_code=502, detail="默认 AI API 配置缺少 model、endpoint 或 apiKey"
        )

    return AiApiConfig(
        provider=str(payload.get("provider") or "custom").strip().lower(),
        model=model,
        endpoint=_strip_chat_completions_suffix(endpoint),
        api_key=api_key,
        max_tokens=payload.get("maxTokens"),
        temperature=payload.get("temperature"),
    )


def _default_config_url(settings: Settings) -> str:
    return settings.urgs_api_url.rstrip("/") + "/api/internal/ai/config/default"


def _default_config_headers(settings: Settings) -> dict[str, str]:
    if not settings.internal_api_token:
        raise HTTPException(status_code=502, detail="缺少内部 API 令牌，无法读取默认 AI API 配置")
    auth_value = settings.internal_api_auth_prefix + settings.internal_api_token
    return {settings.internal_api_auth_header: auth_value}


def _load_default_ai_config_payload(settings: Settings) -> dict[str, Any]:
    url = _default_config_url(settings)
    headers = _default_config_headers(settings)
    last_error: httpx.HTTPError | None = None
    max_attempts = 2
    for attempt in range(max_attempts):
        try:
            response = httpx.get(
                url, headers=headers, timeout=settings.config_request_timeout_seconds
            )
            response.raise_for_status()
            payload = response.json()
            return payload if isinstance(payload, dict) else {}
        except httpx.HTTPStatusError as exc:
            status_code = exc.response.status_code if exc.response is not None else "unknown"
            if attempt + 1 < max_attempts and isinstance(status_code, int) and status_code >= 500:
                last_error = exc
                continue
            raise HTTPException(
                status_code=502,
                detail=f"读取默认 AI API 配置失败: HTTP {status_code}",
            ) from exc
        except httpx.HTTPError as exc:
            last_error = exc
            if attempt + 1 < max_attempts:
                continue
            break
    error_type = last_error.__class__.__name__ if last_error else "HTTPError"
    raise HTTPException(status_code=502, detail=f"读取默认 AI API 配置失败: {error_type}")


def load_default_ai_config(settings: Settings) -> AiApiConfig:
    try:
        return _parse_default_config(_load_default_ai_config_payload(settings))
    except HTTPException:
        raise
    except Exception as exc:
        raise HTTPException(
            status_code=502,
            detail=f"默认 AI API 配置解析失败: {sanitize_text(exc)}",
        ) from exc


def check_model_config_ready(settings: Settings) -> dict[str, Any]:
    if settings.model:
        return {"status": "UP", "source": "DEEPAGENTS_MODEL", "model": settings.model}
    try:
        config = load_default_ai_config(settings)
        return {
            "status": "UP",
            "source": "urgs-api",
            "provider": config.provider,
            "model": config.model,
        }
    except HTTPException as exc:
        return {"status": "DOWN", "source": "urgs-api", "reason": sanitize_text(exc.detail)}


def build_chat_model(settings: Settings, model_override: str | None) -> str | ChatOpenAI:
    if model_override:
        return model_override

    config = load_default_ai_config(settings)
    kwargs: dict[str, Any] = {
        "model": config.model,
        "api_key": config.api_key,
        "base_url": config.endpoint,
        "streaming": True,
    }
    if config.max_tokens is not None:
        kwargs["max_tokens"] = config.max_tokens
    if config.temperature is not None:
        kwargs["temperature"] = config.temperature
    return ReasoningContentChatOpenAI(**kwargs)
