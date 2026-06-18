from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
import json
from typing import Any

from deepagents import __version__, FilesystemPermission, create_deep_agent
from deepagents.backends import FilesystemBackend
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse
from langchain.agents.middleware.types import AgentMiddleware

from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.model_config import build_chat_model
from urgs_deepagents_service.orchestrator import stream_orchestration
from urgs_deepagents_service.schemas import (
    InvokeRequest,
    InvokeResponse,
    OrchestratorRequest,
    RouterRouteRequest,
    RouterRouteResponse,
    UpstreamInfo,
)

UPSTREAM_REPOSITORY = "https://github.com/langchain-ai/deepagents"
UPSTREAM_COMMIT = "4ffea88690418207b5e4fa800ee8c1abfa454bec"
READ_ONLY_FILESYSTEM_PERMISSIONS = [
    FilesystemPermission(operations=["write"], paths=["/**"], mode="deny")
]
DEFAULT_EXCLUDED_TOOLS = frozenset({"execute"})
ROUTER_SYSTEM_PROMPT = """你是 URGS 的 Router Agent，负责把用户任务分发给最合适的业务 Agent。

规则：
1. 只能从请求提供的 agents 列表中选择一个 agent_code。
2. 优先选择最匹配的专业 Agent。
3. 如果没有专业 Agent 适合，选择 agent_type=GENERAL 的通用 Agent；如果列表中存在 general-agent，优先选择 general-agent。
4. 不允许创造新的 agent_code，不允许使用列表外的 Agent。
5. 如果任务需要多个 Agent 协作，仍然先选择主责 Agent，并设置 requires_collaboration=true。
6. 只返回 JSON 对象，不要输出 Markdown，不要输出解释性正文。

JSON 字段：
{
  "agent_code": "从 agents 列表选择的编码",
  "confidence": 0.0 到 1.0 的数字,
  "reason": "选择原因",
  "task_type": "任务类型",
  "requires_collaboration": false,
  "collaboration_plan": ""
}
"""


def _tool_name(tool: Any) -> str | None:
    if isinstance(tool, dict):
        name = tool.get("name")
        return name if isinstance(name, str) else None
    name = getattr(tool, "name", None)
    return name if isinstance(name, str) else None


class ToolVisibilityMiddleware(AgentMiddleware[Any, Any, Any]):
    def __init__(
        self,
        *,
        allowed: frozenset[str] | None = None,
        excluded: frozenset[str] = frozenset(),
    ) -> None:
        self.allowed = allowed
        self.excluded = excluded

    def _filter_tools(self, tools: list[Any]) -> list[Any]:
        if self.allowed is not None:
            return [tool for tool in tools if _tool_name(tool) in self.allowed]
        if self.excluded:
            return [tool for tool in tools if _tool_name(tool) not in self.excluded]
        return tools

    def wrap_model_call(self, request: Any, handler: Any) -> Any:
        return handler(request.override(tools=self._filter_tools(request.tools)))

    async def awrap_model_call(self, request: Any, handler: Any) -> Any:
        return await handler(request.override(tools=self._filter_tools(request.tools)))


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.settings = get_settings()
    yield


def _serialize(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, dict):
        return {key: _serialize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_serialize(item) for item in value]
    return value


def _sse(event: str, payload: Any) -> str:
    return f"event: {event}\ndata: {json.dumps(_serialize(payload), ensure_ascii=False)}\n\n"


def _chunk_text(chunk: Any) -> str:
    content = getattr(chunk, "content", None)
    if isinstance(content, str):
        return content
    if isinstance(content, list):
        parts: list[str] = []
        for item in content:
            if isinstance(item, str):
                parts.append(item)
            elif isinstance(item, dict):
                if item.get("type") == "text" and item.get("text"):
                    parts.append(str(item["text"]))
                elif item.get("type") == "text_delta" and item.get("text"):
                    parts.append(str(item["text"]))
        return "".join(parts)
    return ""


def _assistant_text_from_output(output: Any) -> str:
    value = _serialize(output)
    messages = value.get("messages") if isinstance(value, dict) else None
    if not isinstance(messages, list):
        return _chunk_text(output)
    for message in reversed(messages):
        if not isinstance(message, dict):
            continue
        if message.get("type") not in {"ai", "assistant"} and message.get("role") != "assistant":
            continue
        content = message.get("content")
        if isinstance(content, str):
            return content
        if isinstance(content, list):
            parts: list[str] = []
            for item in content:
                if isinstance(item, str):
                    parts.append(item)
                elif isinstance(item, dict) and item.get("text"):
                    parts.append(str(item["text"]))
            return "".join(parts)
    return ""


def _tool_call_payload(raw: Any) -> dict[str, Any]:
    value = _serialize(raw)
    if isinstance(value, dict):
        return {
            "id": value.get("id") or value.get("tool_call_id"),
            "name": value.get("name") or value.get("tool"),
            "args": value.get("args") or value.get("input"),
        }
    return {"name": str(value)}


def _tool_result_text(raw: Any) -> str:
    value = _serialize(raw)
    if isinstance(value, dict):
        content = value.get("content") or value.get("output")
        if isinstance(content, str):
            return content
    if isinstance(value, str):
        return value
    return json.dumps(value, ensure_ascii=False)


def _normalize_path_list(value: str | list[str] | None) -> list[str]:
    if value is None:
        return []
    if isinstance(value, list):
        return [str(item).strip() for item in value if str(item).strip()]
    items: list[str] = []
    for item in str(value).replace("，", ",").replace("；", ";").splitlines():
        for part in item.replace(";", ",").split(","):
            text = part.strip()
            if text:
                items.append(text)
    return items


def _merge_unique(*values: list[str]) -> list[str]:
    merged: list[str] = []
    seen: set[str] = set()
    for value in values:
        for item in value:
            if item not in seen:
                seen.add(item)
                merged.append(item)
    return merged


def _agent_runtime_kwargs(request: InvokeRequest, settings: Any) -> dict[str, Any]:
    memory_files = _merge_unique(
        _normalize_path_list(settings.memory_files),
        _normalize_path_list(request.memory_files),
    )
    skill_dirs = _merge_unique(
        _normalize_path_list(settings.skill_dirs),
        _normalize_path_list(request.skill_dirs),
    )
    tool_allowlist = frozenset(_normalize_path_list(request.tool_allowlist))
    kwargs: dict[str, Any] = {
        "permissions": READ_ONLY_FILESYSTEM_PERMISSIONS,
        "middleware": [
            ToolVisibilityMiddleware(
                allowed=tool_allowlist if tool_allowlist else None,
                excluded=DEFAULT_EXCLUDED_TOOLS if not tool_allowlist else frozenset(),
            )
        ],
        "debug": request.debug,
    }
    if settings.workspace_root:
        kwargs["backend"] = FilesystemBackend(root_dir=settings.workspace_root, virtual_mode=True)
    elif memory_files or skill_dirs:
        raise HTTPException(
            status_code=400,
            detail="配置 memory_files 或 skill_dirs 需要设置 DEEPAGENTS_WORKSPACE_ROOT",
        )
    if memory_files:
        kwargs["memory"] = memory_files
    if skill_dirs:
        kwargs["skills"] = skill_dirs
    return kwargs


def _agent_catalog_text(request: RouterRouteRequest) -> str:
    rows: list[str] = []
    for agent in request.agents:
        rows.append(
            json.dumps(
                {
                    "agent_code": agent.agent_code,
                    "agent_name": agent.agent_name,
                    "agent_type": agent.agent_type,
                    "build_mode": agent.build_mode,
                    "description": agent.description,
                    "capability_tags": agent.capability_tags,
                    "routing_examples": agent.routing_examples,
                    "sort_order": agent.sort_order,
                },
                ensure_ascii=False,
            )
        )
    return "\n".join(rows)


def _router_user_prompt(request: RouterRouteRequest) -> str:
    return (
        "用户任务：\n"
        f"{request.message}\n\n"
        "可选 agents，每行一个 JSON：\n"
        f"{_agent_catalog_text(request)}\n\n"
        "请选择唯一主责 Agent。"
    )


def _route_response_from_result(result: Any) -> RouterRouteResponse:
    value = _serialize(result)
    if isinstance(value, dict):
        structured = value.get("structured_response")
        if structured:
            return RouterRouteResponse.model_validate(structured)
    text = _assistant_text_from_output(result).strip()
    start = text.find("{")
    end = text.rfind("}")
    if start >= 0 and end > start:
        return RouterRouteResponse.model_validate(json.loads(text[start : end + 1]))
    raise ValueError("Router Agent 未返回结构化路由结果")


async def _stream_deep_agent(request: InvokeRequest, settings: Any) -> AsyncIterator[str]:
    try:
        model = build_chat_model(settings, request.model or settings.model)
        runtime_kwargs = _agent_runtime_kwargs(request, settings)
        agent = create_deep_agent(
            model=model,
            tools=[],
            system_prompt=request.system_prompt,
            **runtime_kwargs,
        )
        emitted_text = False
        yield _sse("agent", {"type": "thinking", "title": "正在思考", "content": "正在分析问题并规划下一步"})
        async for event in agent.astream_events({"messages": request.messages}, version="v2"):
            event_name = event.get("event")
            name = event.get("name") or ""
            data = event.get("data") or {}

            if event_name == "on_chain_start" and name == "model":
                yield _sse("agent", {"type": "thinking", "title": "正在组织回答", "content": "正在调用模型生成响应"})
                continue

            if event_name == "on_chat_model_stream":
                text = _chunk_text(data.get("chunk"))
                if text:
                    emitted_text = True
                    yield _sse("content", {"content": text})
                continue

            if event_name == "on_tool_start":
                yield _sse(
                    "agent",
                    {
                        "type": "tool_call",
                        "title": f"调用工具 {name}",
                        "toolName": name,
                        "args": data.get("input"),
                    },
                )
                continue

            if event_name == "on_tool_end":
                yield _sse(
                    "agent",
                    {
                        "type": "tool_result",
                        "title": f"工具 {name} 返回结果",
                        "toolName": name,
                        "content": _tool_result_text(data.get("output")),
                    },
                )
                continue

            if event_name == "on_chat_model_end":
                output = data.get("output")
                if not emitted_text:
                    text = _chunk_text(output)
                    if text:
                        emitted_text = True
                        yield _sse("content", {"content": text})
                for tool_call in getattr(output, "tool_calls", []) or []:
                    payload = _tool_call_payload(tool_call)
                    yield _sse(
                        "agent",
                        {
                            "type": "tool_call",
                            "title": f"准备调用工具 {payload.get('name') or 'unknown'}",
                            "toolName": payload.get("name"),
                            "toolCallId": payload.get("id"),
                            "args": payload.get("args"),
                        },
                    )
                continue

            if event_name == "on_chain_end" and name == "LangGraph" and not emitted_text:
                text = _assistant_text_from_output(data.get("output"))
                if text:
                    emitted_text = True
                    yield _sse("content", {"content": text})

        yield _sse("done", {"done": True})
    except Exception as exc:
        yield _sse("error", {"error": f"DeepAgents 调用失败: {exc}"})


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="URGS DeepAgents Service", version="0.1.0", lifespan=lifespan)

    @app.get("/health/live", tags=["health"])
    def live() -> dict[str, str]:
        return {"status": "UP", "service": settings.service_name}

    @app.get("/v1/upstream", response_model=UpstreamInfo, tags=["deepagents"])
    def upstream() -> UpstreamInfo:
        return UpstreamInfo(
            package="deepagents",
            version=__version__,
            repository=UPSTREAM_REPOSITORY,
            commit=UPSTREAM_COMMIT,
            license="MIT",
        )

    @app.post("/v1/router/route", response_model=RouterRouteResponse, tags=["router"])
    def route(request: RouterRouteRequest) -> RouterRouteResponse:
        if not request.agents:
            raise HTTPException(status_code=400, detail="agents 不能为空")
        try:
            model = build_chat_model(settings, request.model or settings.model)
            router = create_deep_agent(
                model=model,
                tools=[],
                system_prompt=ROUTER_SYSTEM_PROMPT,
                permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
                middleware=[ToolVisibilityMiddleware(allowed=frozenset())],
                debug=request.debug,
            )
            result = router.invoke(
                {"messages": [{"role": "user", "content": _router_user_prompt(request)}]}
            )
            decision = _route_response_from_result(result)
            allowed_agent_codes = {agent.agent_code for agent in request.agents}
            if decision.agent_code not in allowed_agent_codes:
                raise HTTPException(
                    status_code=422,
                    detail=f"Router Agent 返回了未注册的 agent_code: {decision.agent_code}",
                )
            return decision
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f"Router Agent 分发失败: {exc}") from exc

    @app.post("/v1/agents/invoke", response_model=InvokeResponse, tags=["deepagents"])
    def invoke(request: InvokeRequest) -> InvokeResponse:
        try:
            model = build_chat_model(settings, request.model or settings.model)
            runtime_kwargs = _agent_runtime_kwargs(request, settings)
            agent = create_deep_agent(
                model=model,
                tools=[],
                system_prompt=request.system_prompt,
                **runtime_kwargs,
            )
            result = agent.invoke({"messages": request.messages})
            return InvokeResponse(output=_serialize(result))
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(status_code=502, detail=f"DeepAgents 调用失败: {exc}") from exc

    @app.post("/v1/agents/stream", tags=["deepagents"])
    def stream(request: InvokeRequest) -> StreamingResponse:
        return StreamingResponse(
            _stream_deep_agent(request, settings),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    @app.post("/v1/orchestrator/stream", tags=["orchestrator"])
    def orchestrator_stream(request: OrchestratorRequest) -> StreamingResponse:
        return StreamingResponse(
            stream_orchestration(request, settings),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    return app


app = create_app()
