from datetime import datetime
from typing import Any, Literal
from uuid import UUID

from pydantic import AnyHttpUrl, BaseModel, ConfigDict, Field, model_validator

from urgs_agent.domain.enums import AgentStatus, RunStatus, VersionStatus


class ModelTarget(BaseModel):
    provider: str = "openai_compatible"
    model: str
    base_url: str | None = None
    api_key_env: str | None = None


class ModelPolicy(BaseModel):
    primary: ModelTarget
    fallbacks: list[ModelTarget] = Field(default_factory=list)
    temperature: float = Field(default=0.1, ge=0, le=2)
    max_tokens: int = Field(default=4096, ge=1)
    timeout_seconds: float = Field(default=60, gt=0)
    max_attempts: int = Field(default=2, ge=1, le=5)


class RunLimits(BaseModel):
    timeout_seconds: int = Field(default=600, ge=1, le=86400)
    max_steps: int = Field(default=30, ge=1, le=200)
    max_model_calls: int = Field(default=20, ge=1, le=100)
    max_tokens: int = Field(default=100000, ge=1)


class SpecialistConfig(BaseModel):
    id: str = Field(pattern=r"^[a-z][a-z0-9_-]{1,63}$")
    description: str
    system_prompt: str
    tools: list[str] = Field(default_factory=list)


class WorkflowDefinition(BaseModel):
    template: Literal["react", "router", "supervisor"]
    system_prompt: str
    model: ModelPolicy
    tools: list[str] = Field(default_factory=list)
    required_permissions: list[str] = Field(default_factory=list)
    limits: RunLimits = Field(default_factory=RunLimits)
    specialists: list[SpecialistConfig] = Field(default_factory=list)
    require_tool_approval: list[str] = Field(default_factory=list)

    @model_validator(mode="after")
    def validate_template_shape(self) -> "WorkflowDefinition":
        if self.template == "supervisor" and len(self.specialists) < 2:
            raise ValueError("supervisor template requires at least two specialists")
        ids = [item.id for item in self.specialists]
        if len(ids) != len(set(ids)):
            raise ValueError("specialist ids must be unique")
        return self


class AgentCreate(BaseModel):
    agent_id: str = Field(pattern=r"^[a-z][a-z0-9_-]{2,63}$")
    name: str = Field(min_length=1, max_length=200)
    description: str = Field(default="", max_length=2000)


class AgentRead(AgentCreate):
    model_config = ConfigDict(from_attributes=True)
    status: AgentStatus
    published_version: int | None
    created_at: datetime
    updated_at: datetime


class AgentVersionCreate(BaseModel):
    definition: WorkflowDefinition


class AgentVersionRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    agent_id: str
    version: int
    status: VersionStatus
    config_hash: str
    definition: WorkflowDefinition
    created_at: datetime
    published_at: datetime | None


class RunCreate(BaseModel):
    tenant_id: str | None = None
    user_id: str | None = None
    operator_id: str | None = None
    business_id: str | None = None
    conversation_id: str
    thread_id: str
    request_id: str
    trace_id: str
    agent_id: str
    agent_version: int | None = None
    input: str | dict[str, Any]
    metadata: dict[str, Any] = Field(default_factory=dict)
    permissions: list[str] = Field(default_factory=list)
    callback_url: AnyHttpUrl | None = None
    wait_seconds: int = Field(default=0, ge=0, le=60)


class RunRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    run_id: UUID
    tenant_id: str | None
    conversation_id: str
    thread_id: str
    request_id: str
    trace_id: str
    agent_id: str
    agent_version: int
    status: RunStatus
    input: str | dict[str, Any]
    output: dict[str, Any] | None
    error: dict[str, Any] | None
    created_at: datetime
    started_at: datetime | None
    finished_at: datetime | None


class ResumeRunRequest(BaseModel):
    value: Any


class EventRead(BaseModel):
    model_config = ConfigDict(from_attributes=True)
    event_id: UUID
    event_type: str
    sequence: int
    timestamp: datetime
    run_id: UUID
    thread_id: str
    request_id: str
    trace_id: str
    agent_id: str
    agent_version: int
    node_id: str | None
    payload: dict[str, Any]
