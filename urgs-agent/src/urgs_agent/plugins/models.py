import os
from collections.abc import Callable, Sequence
from typing import Any

from langchain_core.callbacks.manager import CallbackManagerForLLMRun
from langchain_core.language_models.chat_models import BaseChatModel
from langchain_core.messages import AIMessage, BaseMessage, ToolMessage
from langchain_core.outputs import ChatGeneration, ChatResult
from langchain_core.runnables import Runnable
from langchain_core.tools import BaseTool
from langchain_openai import ChatOpenAI

from urgs_agent.config import Settings
from urgs_agent.domain.schemas import ModelPolicy, ModelTarget
from urgs_agent.plugins.contracts import ModelProvider


class OpenAICompatibleProvider(ModelProvider):
    name = "openai_compatible"

    def __init__(self, settings: Settings) -> None:
        self.settings = settings

    def create(self, target: ModelTarget, **kwargs: Any) -> BaseChatModel:
        api_key = self.settings.openai_api_key
        if target.api_key_env:
            api_key = os.environ.get(target.api_key_env, "")
        return ChatOpenAI(
            model=target.model,
            base_url=target.base_url or self.settings.openai_base_url,
            api_key=api_key,
            streaming=True,
            **kwargs,
        )


class MockChatModel(BaseChatModel):
    response: str = "mock response"

    @property
    def _llm_type(self) -> str:
        return "urgs-mock"

    def _generate(
        self,
        messages: list[BaseMessage],
        stop: list[str] | None = None,
        run_manager: CallbackManagerForLLMRun | None = None,
        **kwargs: Any,
    ) -> ChatResult:
        if self.response.startswith("tool:") and not any(
            isinstance(message, ToolMessage) for message in messages
        ):
            tool_name = self.response.removeprefix("tool:")
            message = AIMessage(
                content="",
                tool_calls=[
                    {
                        "name": tool_name,
                        "args": {},
                        "id": "mock-tool-call",
                    }
                ],
            )
        elif self.response.startswith("tool:"):
            message = AIMessage(content="mock tool flow completed")
        else:
            message = AIMessage(content=self.response)
        return ChatResult(generations=[ChatGeneration(message=message)])

    def bind_tools(
        self,
        tools: Sequence[dict[str, Any] | type | Callable[..., Any] | BaseTool],
        *,
        tool_choice: str | None = None,
        **kwargs: Any,
    ) -> Runnable[Any, BaseMessage]:
        return self


class MockModelProvider(ModelProvider):
    name = "mock"

    def create(self, target: ModelTarget, **kwargs: Any) -> BaseChatModel:
        return MockChatModel(response=target.model)


class ModelRegistry:
    def __init__(self) -> None:
        self._providers: dict[str, ModelProvider] = {}

    def register(self, provider: ModelProvider) -> None:
        self._providers[provider.name] = provider

    def create_candidates(self, policy: ModelPolicy) -> list[tuple[ModelTarget, BaseChatModel]]:
        targets = [policy.primary, *policy.fallbacks]
        models: list[tuple[ModelTarget, BaseChatModel]] = []
        for target in targets:
            provider = self._providers.get(target.provider)
            if provider is None:
                raise ValueError(f"unknown model provider: {target.provider}")
            models.append(
                (
                    target,
                    provider.create(
                        target,
                        temperature=policy.temperature,
                        max_tokens=policy.max_tokens,
                        timeout=policy.timeout_seconds,
                        max_retries=policy.max_attempts - 1,
                    ),
                )
            )
        return models
