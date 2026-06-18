import json
from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from fastapi import FastAPI, HTTPException
from fastapi.responses import JSONResponse, StreamingResponse

from deepagents import __version__
from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.model_config import build_chat_model, check_model_config_ready
from urgs_deepagents_service.observability import request_context_middleware, setup_logging
from urgs_deepagents_service.orchestrator import stream_orchestration
from urgs_deepagents_service.orchestrator.utils import (
    assistant_text_from_output,
    chunk_text,
    tool_call_payload,
    tool_result_text,
)
from urgs_deepagents_service.runtime import (
    DEFAULT_EXCLUDED_TOOLS as DEFAULT_EXCLUDED_TOOLS,
)
from urgs_deepagents_service.runtime import (
    READ_ONLY_FILESYSTEM_PERMISSIONS as READ_ONLY_FILESYSTEM_PERMISSIONS,
)
from urgs_deepagents_service.runtime import (
    ToolVisibilityMiddleware as ToolVisibilityMiddleware,
)
from urgs_deepagents_service.runtime import (
    build_agent_kwargs,
    create_control_agent,
    create_runtime_agent,
    graph_config,
)
from urgs_deepagents_service.schemas import (
    InvokeRequest,
    InvokeResponse,
    OrchestratorRequest,
    RouterRouteRequest,
    RouterRouteResponse,
    UpstreamInfo,
)
from urgs_deepagents_service.sse import StreamContext, sanitize_text, serialize, sse

UPSTREAM_REPOSITORY = "https://github.com/langchain-ai/deepagents"
UPSTREAM_COMMIT = "4ffea88690418207b5e4fa800ee8c1abfa454bec"
ROUTER_SYSTEM_PROMPT = """你是 URGS 的 Router Agent，负责把用户任务分发给最合适的业务 Agent。

规则：
1. 只能从请求提供的 agents 列表中选择一个 agent_code。
2. 优先选择最匹配的专业 Agent。
3. 如果没有专业 Agent 适合，选择 agent_type=GENERAL 的通用 Agent；
   如果列表中存在 general-agent，优先选择 general-agent。
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


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.settings = get_settings()
    yield


_serialize = serialize
_sse = sse
_chunk_text = chunk_text
_assistant_text_from_output = assistant_text_from_output
_tool_call_payload = tool_call_payload
_tool_result_text = tool_result_text
_graph_config = graph_config


def _agent_runtime_kwargs(request: InvokeRequest, settings: Any) -> dict[str, Any]:
    return build_agent_kwargs(
        settings=settings,
        memory_files=request.memory_files,
        skill_dirs=request.skill_dirs,
        tool_allowlist=request.tool_allowlist,
        allow_write=False,
        workspace_root=None,
        debug=request.debug,
    )


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
    context = StreamContext(agent_code=request.agent_code)
    try:
        model = build_chat_model(settings, request.model or settings.model)
        agent = create_runtime_agent(
            model=model,
            settings=settings,
            system_prompt=request.system_prompt,
            memory_files=request.memory_files,
            skill_dirs=request.skill_dirs,
            tool_allowlist=request.tool_allowlist,
            allow_write=False,
            workspace_root=None,
            debug=request.debug,
        )
        emitted_text = False
        tool_inputs: dict[str, Any] = {}
        yield _sse(
            "agent",
            {"type": "thinking", "title": "正在思考", "content": "正在分析问题并规划下一步"},
            context,
            step_id="agent.thinking",
            status="started",
            message="正在分析问题并规划下一步",
        )
        async for event in agent.astream_events(
            {"messages": request.messages}, config=_graph_config(settings), version="v2"
        ):
            event_name = event.get("event")
            name = event.get("name") or ""
            data = event.get("data") or {}
            run_id = event.get("run_id")

            if event_name == "on_chain_start" and name == "model":
                yield _sse(
                    "agent",
                    {
                        "type": "thinking",
                        "title": "正在组织回答",
                        "content": "正在调用模型生成响应",
                    },
                    context,
                    step_id="agent.model",
                    status="started",
                    message="正在调用模型生成响应",
                )
                continue

            if event_name == "on_chat_model_stream":
                text = _chunk_text(data.get("chunk"))
                if text:
                    emitted_text = True
                    yield _sse(
                        "content",
                        {"content": text},
                        context,
                        step_id="agent.content",
                        status="streaming",
                        message="内容增量",
                    )
                continue

            if event_name == "on_tool_start":
                if run_id:
                    tool_inputs[run_id] = data.get("input")
                yield _sse(
                    "agent",
                    {
                        "type": "tool_call",
                        "title": f"调用工具 {name}",
                        "toolName": name,
                        "args": data.get("input"),
                    },
                    context,
                    step_id=f"tool.{name}.start",
                    status="started",
                    message=f"调用工具 {name}",
                )
                continue

            if event_name == "on_tool_end":
                output = data.get("output")
                payload: dict[str, Any] = {
                    "type": "tool_result",
                    "title": f"工具 {name} 返回结果",
                    "toolName": name,
                    "content": _tool_result_text(output),
                }
                if run_id and run_id in tool_inputs:
                    payload["args"] = tool_inputs.pop(run_id)
                status = getattr(output, "status", None)
                if status:
                    payload["status"] = status
                yield _sse(
                    "agent",
                    payload,
                    context,
                    step_id=f"tool.{name}.end",
                    status="completed",
                    message=f"工具 {name} 返回结果",
                )
                continue

            if event_name == "on_chat_model_end":
                output = data.get("output")
                if not emitted_text:
                    text = _chunk_text(output)
                    if text:
                        emitted_text = True
                        yield _sse(
                            "content",
                            {"content": text},
                            context,
                            step_id="agent.content",
                            status="streaming",
                            message="内容增量",
                        )
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
                        context,
                        step_id=f"tool.{payload.get('name') or 'unknown'}.prepared",
                        status="started",
                        message=f"准备调用工具 {payload.get('name') or 'unknown'}",
                    )
                continue

            if event_name == "on_chain_end" and name == "LangGraph" and not emitted_text:
                text = _assistant_text_from_output(data.get("output"))
                if text:
                    emitted_text = True
                    yield _sse(
                        "content",
                        {"content": text},
                        context,
                        step_id="agent.content",
                        status="streaming",
                        message="内容增量",
                    )

        yield _sse(
            "done",
            {"done": True},
            context,
            step_id="agent.done",
            status="completed",
            message="DeepAgent 调用完成",
        )
    except Exception as exc:
        yield _sse(
            "error",
            {
                "error": "DeepAgents 调用失败",
                "error_type": exc.__class__.__name__,
                "detail": sanitize_text(exc),
            },
            context,
            step_id="agent.error",
            status="failed",
            message="DeepAgents 调用失败",
        )


def create_app() -> FastAPI:
    settings = get_settings()
    setup_logging(settings.log_level)
    app = FastAPI(title="URGS DeepAgents Service", version="0.1.0", lifespan=lifespan)
    app.middleware("http")(request_context_middleware)

    @app.get("/health/live", tags=["health"])
    def live() -> dict[str, str]:
        return {"status": "UP", "service": settings.service_name}

    @app.get("/health/ready", tags=["health"])
    def ready() -> JSONResponse:
        model_config = check_model_config_ready(settings)
        ready_status = model_config.get("status") == "UP"
        body = {
            "status": "UP" if ready_status else "DOWN",
            "service": settings.service_name,
            "dependencies": {"model_config": model_config},
        }
        return JSONResponse(status_code=200 if ready_status else 503, content=body)

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
            router = create_control_agent(
                model=model,
                system_prompt=ROUTER_SYSTEM_PROMPT,
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
            raise HTTPException(
                status_code=502,
                detail=f"Router Agent 分发失败: {sanitize_text(exc)}",
            ) from exc

    @app.post("/v1/agents/invoke", response_model=InvokeResponse, tags=["deepagents"])
    def invoke(request: InvokeRequest) -> InvokeResponse:
        try:
            model = build_chat_model(settings, request.model or settings.model)
            agent = create_runtime_agent(
                model=model,
                settings=settings,
                system_prompt=request.system_prompt,
                memory_files=request.memory_files,
                skill_dirs=request.skill_dirs,
                tool_allowlist=request.tool_allowlist,
                allow_write=False,
                workspace_root=None,
                debug=request.debug,
            )
            result = agent.invoke({"messages": request.messages}, config=_graph_config(settings))
            return InvokeResponse(output=_serialize(result))
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail=f"DeepAgents 调用失败: {sanitize_text(exc)}",
            ) from exc

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
