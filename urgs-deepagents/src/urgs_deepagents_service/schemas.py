from typing import Any

from pydantic import BaseModel, Field


class InvokeRequest(BaseModel):
    messages: str | list[dict[str, Any]] = Field(
        description="User input string or LangChain-compatible message dictionaries."
    )
    system_prompt: str | None = Field(default=None, description="Optional system prompt.")
    model: str | None = Field(default=None, description="Optional provider:model override.")
    agent_code: str | None = Field(default=None, description="Optional platform agent code.")
    memory_files: str | list[str] | None = Field(default=None, description="Agent memory file paths.")
    skill_dirs: str | list[str] | None = Field(default=None, description="Agent skill directory paths.")
    tool_allowlist: str | list[str] | None = Field(default=None, description="Allowed tool names.")
    debug: bool = False


class InvokeResponse(BaseModel):
    output: dict[str, Any]


class RouterAgentDescriptor(BaseModel):
    agent_code: str
    agent_name: str
    agent_type: str | None = None
    build_mode: str | None = None
    description: str | None = None
    capability_tags: str | list[str] | None = None
    routing_examples: str | list[str] | None = None
    sort_order: int | None = None


class RouterRouteRequest(BaseModel):
    message: str
    agents: list[RouterAgentDescriptor]
    model: str | None = Field(default=None, description="Optional provider:model override.")
    debug: bool = False


class RouterRouteResponse(BaseModel):
    agent_code: str
    confidence: float = Field(ge=0.0, le=1.0)
    reason: str
    task_type: str = ""
    requires_collaboration: bool = False
    collaboration_plan: str = ""


class UpstreamInfo(BaseModel):
    package: str
    version: str
    repository: str
    commit: str
    license: str
