from abc import ABC, abstractmethod
from collections.abc import Awaitable, Callable
from dataclasses import dataclass, field
from typing import Any

from langchain_core.language_models.chat_models import BaseChatModel
from pydantic import BaseModel

from urgs_agent.domain.schemas import ModelTarget

EventSink = Callable[[str, dict[str, Any], str | None], Awaitable[None]]


@dataclass(frozen=True)
class ToolContext:
    run_id: str
    request_id: str
    trace_id: str
    permissions: frozenset[str]
    metadata: dict[str, Any] = field(default_factory=dict)
    event_sink: EventSink | None = None


class ToolPlugin(ABC):
    name: str
    description: str
    args_schema: type[BaseModel]
    required_permissions: frozenset[str] = frozenset()
    idempotent: bool = True

    @abstractmethod
    async def execute(self, arguments: dict[str, Any], context: ToolContext) -> dict[str, Any]:
        raise NotImplementedError

    def openai_schema(self) -> dict[str, Any]:
        return {
            "type": "function",
            "function": {
                "name": self.name,
                "description": self.description,
                "parameters": self.args_schema.model_json_schema(),
            },
        }


class ModelProvider(ABC):
    name: str

    @abstractmethod
    def create(self, target: ModelTarget, **kwargs: Any) -> BaseChatModel:
        raise NotImplementedError


class Retriever(ABC):
    name: str

    @abstractmethod
    async def search(
        self, query: str, knowledge_bases: list[str], context: ToolContext
    ) -> list[dict[str, Any]]:
        raise NotImplementedError
