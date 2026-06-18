from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
import json
from typing import Any

from deepagents import __version__, FilesystemPermission, create_deep_agent
from fastapi import FastAPI, HTTPException
from fastapi.responses import StreamingResponse

from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.model_config import build_chat_model
from urgs_deepagents_service.schemas import InvokeRequest, InvokeResponse, UpstreamInfo

UPSTREAM_REPOSITORY = "https://github.com/langchain-ai/deepagents"
UPSTREAM_COMMIT = "4ffea88690418207b5e4fa800ee8c1abfa454bec"
READ_ONLY_FILESYSTEM_PERMISSIONS = [
    FilesystemPermission(operations=["write"], paths=["/**"], mode="deny")
]


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


async def _stream_deep_agent(request: InvokeRequest, settings: Any) -> AsyncIterator[str]:
    try:
        model = build_chat_model(settings, request.model or settings.model)
        agent = create_deep_agent(
            model=model,
            tools=[],
            system_prompt=request.system_prompt,
            permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
            debug=request.debug,
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

    @app.post("/v1/agents/invoke", response_model=InvokeResponse, tags=["deepagents"])
    def invoke(request: InvokeRequest) -> InvokeResponse:
        try:
            model = build_chat_model(settings, request.model or settings.model)
            agent = create_deep_agent(
                model=model,
                tools=[],
                system_prompt=request.system_prompt,
                permissions=READ_ONLY_FILESYSTEM_PERMISSIONS,
                debug=request.debug,
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

    return app


app = create_app()
