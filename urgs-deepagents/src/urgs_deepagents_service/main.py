from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from hmac import compare_digest
from typing import Any

from fastapi import Depends, FastAPI, HTTPException, Request
from fastapi.responses import JSONResponse, StreamingResponse

from deepagents import __version__
from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.model_config import build_chat_model, check_model_config_ready
from urgs_deepagents_service.observability import request_context_middleware, setup_logging
from urgs_deepagents_service.orchestrator import stream_orchestration
from urgs_deepagents_service.orchestrator.router import run_router
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
            agent_code=request.agent_code,
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

    def require_internal_auth(request: Request) -> None:
        if not settings.internal_api_token:
            return
        actual = request.headers.get(settings.internal_api_auth_header, "")
        expected = settings.internal_api_auth_prefix + settings.internal_api_token
        if compare_digest(actual, expected) or compare_digest(actual, settings.internal_api_token):
            return
        raise HTTPException(status_code=401, detail="内部 API 鉴权失败")

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

    @app.post(
        "/v1/router/route",
        response_model=RouterRouteResponse,
        tags=["router"],
        dependencies=[Depends(require_internal_auth)],
    )
    async def route(request: RouterRouteRequest) -> RouterRouteResponse:
        if not request.agents:
            raise HTTPException(status_code=400, detail="agents 不能为空")
        try:
            model = build_chat_model(settings, request.model or settings.model)
            decision = await run_router(
                model=model,
                user_message=request.message,
                agents=request.agents,
                current_agent_code=request.current_agent_code,
                conversation_context=request.conversation_context or "",
            )
            return RouterRouteResponse(
                agent_code=decision.agent_code,
                confidence=decision.confidence,
                reason=decision.reason,
                task_type=decision.task_type,
                requires_collaboration=decision.is_complex,
                collaboration_plan=decision.collaboration_plan,
                reused_current_agent=decision.reused_current_agent,
            )
        except HTTPException:
            raise
        except Exception as exc:
            raise HTTPException(
                status_code=502,
                detail=f"Router Agent 分发失败: {sanitize_text(exc)}",
            ) from exc

    @app.post(
        "/v1/agents/invoke",
        response_model=InvokeResponse,
        tags=["deepagents"],
        dependencies=[Depends(require_internal_auth)],
    )
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
                agent_code=request.agent_code,
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

    @app.post(
        "/v1/agents/stream", tags=["deepagents"], dependencies=[Depends(require_internal_auth)]
    )
    def stream(request: InvokeRequest) -> StreamingResponse:
        return StreamingResponse(
            _stream_deep_agent(request, settings),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    @app.post(
        "/v1/orchestrator/stream",
        tags=["orchestrator"],
        dependencies=[Depends(require_internal_auth)],
    )
    def orchestrator_stream(request: OrchestratorRequest) -> StreamingResponse:
        return StreamingResponse(
            stream_orchestration(request, settings),
            media_type="text/event-stream",
            headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"},
        )

    return app


app = create_app()
