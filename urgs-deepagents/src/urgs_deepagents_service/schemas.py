from typing import Any

from pydantic import BaseModel, Field


class InvokeRequest(BaseModel):
    messages: str | list[dict[str, Any]] = Field(
        description="User input string or LangChain-compatible message dictionaries."
    )
    system_prompt: str | None = Field(default=None, description="Optional system prompt.")
    model: str | None = Field(default=None, description="Optional provider:model override.")
    agent_code: str | None = Field(default=None, description="Optional platform agent code.")
    memory_files: str | list[str] | None = Field(
        default=None, description="Agent memory file paths."
    )
    skill_dirs: str | list[str] | None = Field(
        default=None, description="Agent skill directory paths."
    )
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
    current_agent_code: str | None = Field(
        default=None, description="当前会话上一次自动路由使用的 agent_code；仅作为软绑定参考"
    )
    conversation_context: str | None = Field(
        default=None, description="可选历史对话摘要，辅助判断是否延续当前 Agent"
    )
    model: str | None = Field(default=None, description="Optional provider:model override.")
    debug: bool = False


class RouterRouteResponse(BaseModel):
    agent_code: str
    confidence: float = Field(ge=0.0, le=1.0)
    reason: str
    task_type: str = ""
    requires_collaboration: bool = False
    collaboration_plan: str = ""
    reused_current_agent: bool = False


class AgentRuntimeConfig(BaseModel):
    """编排请求中单个 Agent 的运行时配置，与 API 侧 Agent 字段对应。"""

    system_prompt: str | None = Field(default=None, description="Agent 系统提示词")
    memory_files: str | list[str] | None = Field(
        default=None, description="DeepAgents memory 文件列表"
    )
    skill_dirs: str | list[str] | None = Field(
        default=None, description="DeepAgents skills 目录列表"
    )
    tool_allowlist: str | list[str] | None = Field(default=None, description="允许调用的工具白名单")
    allow_write: bool = Field(default=False, description="是否允许写工作区（默认只读）")
    workspace_root: str | None = Field(
        default=None, description="Agent 级工作空间根目录，覆盖全局 DEEPAGENTS_WORKSPACE_ROOT"
    )
    execution_context: dict[str, Any] | None = Field(
        default=None, description="服务端生成的通用 Agent 执行上下文"
    )


class OrchestratorRequest(BaseModel):
    """多 Agent 编排请求。编排接口内部完成路由，API 无需单独调用 router。"""

    messages: str | list[dict[str, Any]] = Field(
        description="User input string or LangChain-compatible message dictionaries."
    )
    agents: list[RouterAgentDescriptor] = Field(
        description="可选 Agent 目录，供 Router/Planner 选择"
    )
    agent_configs: dict[str, AgentRuntimeConfig] | None = Field(
        default=None,
        description="agent_code -> 运行时配置映射；未提供的 agent 视为非 DEEPAGENTS，触发 handoff",
    )
    selected_agent_code: str | None = Field(
        default=None, description="手动预选 Agent；提供时跳过 Router，仍执行 Input Guard 与后续编排"
    )
    current_agent_code: str | None = Field(
        default=None, description="当前会话上一次自动路由使用的 Agent；Router 可复用也可重选"
    )
    system_prompt: str | None = Field(default=None, description="平台级兜底系统提示词")
    model: str | None = Field(default=None, description="Optional provider:model override.")
    debug: bool = False


class UpstreamInfo(BaseModel):
    package: str
    version: str
    repository: str
    commit: str
    license: str
