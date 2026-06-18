from typing import Any

from pydantic import BaseModel, Field


class InvokeRequest(BaseModel):
    messages: str | list[dict[str, Any]] = Field(
        description="User input string or LangChain-compatible message dictionaries."
    )
    system_prompt: str | None = Field(default=None, description="Optional system prompt.")
    model: str | None = Field(default=None, description="Optional provider:model override.")
    debug: bool = False


class InvokeResponse(BaseModel):
    output: dict[str, Any]


class UpstreamInfo(BaseModel):
    package: str
    version: str
    repository: str
    commit: str
    license: str

