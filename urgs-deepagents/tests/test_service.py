import json
from types import SimpleNamespace

import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from langchain_openai import ChatOpenAI

from urgs_deepagents_service.main import (
    DEFAULT_EXCLUDED_TOOLS,
    READ_ONLY_FILESYSTEM_PERMISSIONS,
    ToolVisibilityMiddleware,
    _agent_runtime_kwargs,
    app,
)
from urgs_deepagents_service.model_config import _parse_default_config, build_chat_model
from urgs_deepagents_service.schemas import InvokeRequest


def _parse_sse(raw: str) -> list[tuple[str, dict[str, object]]]:
    events: list[tuple[str, dict[str, object]]] = []
    for block in raw.strip().split("\n\n"):
        if not block:
            continue
        lines = block.splitlines()
        event = lines[0].removeprefix("event: ").strip()
        data = lines[1].removeprefix("data: ").strip()
        events.append((event, json.loads(data)))
    return events


def test_health_live() -> None:
    client = TestClient(app)

    response = client.get("/health/live")

    assert response.status_code == 200
    assert response.json()["status"] == "UP"


def test_upstream_info() -> None:
    client = TestClient(app)

    response = client.get("/v1/upstream")

    assert response.status_code == 200
    body = response.json()
    assert body["package"] == "deepagents"
    assert body["commit"] == "4ffea88690418207b5e4fa800ee8c1abfa454bec"


def test_deepagents_filesystem_write_is_denied() -> None:
    assert len(READ_ONLY_FILESYSTEM_PERMISSIONS) == 1
    permission = READ_ONLY_FILESYSTEM_PERMISSIONS[0]
    assert permission.operations == ["write"]
    assert permission.paths == ["/**"]
    assert permission.mode == "deny"


def test_deepagents_default_tool_visibility_hides_execute() -> None:
    middleware = ToolVisibilityMiddleware(excluded=DEFAULT_EXCLUDED_TOOLS)

    tools = [{"name": "execute"}, {"name": "read_file"}, {"name": "grep"}]

    assert middleware._filter_tools(tools) == [{"name": "read_file"}, {"name": "grep"}]


def test_deepagents_tool_allowlist_filters_all_other_tools() -> None:
    middleware = ToolVisibilityMiddleware(allowed=frozenset({"read_file", "grep"}))

    tools = [{"name": "execute"}, {"name": "read_file"}, {"name": "grep"}, {"name": "write_file"}]

    assert middleware._filter_tools(tools) == [{"name": "read_file"}, {"name": "grep"}]


def test_agent_runtime_requires_workspace_for_memory_files() -> None:
    class FakeSettings:
        workspace_root = None
        memory_files = ""
        skill_dirs = ""

    request = InvokeRequest(messages="hello", memory_files=["/AGENTS.md"])

    with pytest.raises(HTTPException) as exc_info:
        _agent_runtime_kwargs(request, FakeSettings())

    assert exc_info.value.status_code == 400


def test_agent_runtime_merges_workspace_memory_skills_and_tool_allowlist(tmp_path) -> None:
    class FakeSettings:
        workspace_root = str(tmp_path)
        memory_files = "/AGENTS.md"
        skill_dirs = "/skills/platform"

    request = InvokeRequest(
        messages="hello",
        memory_files=["/agents/frontend/AGENTS.md"],
        skill_dirs="/skills/frontend",
        tool_allowlist=["read_file", "grep"],
    )

    kwargs = _agent_runtime_kwargs(request, FakeSettings())
    middleware = kwargs["middleware"][0]

    assert kwargs["memory"] == ["/AGENTS.md", "/agents/frontend/AGENTS.md"]
    assert kwargs["skills"] == ["/skills/platform", "/skills/frontend"]
    assert middleware.allowed == frozenset({"read_file", "grep"})


def test_agents_invoke_basic_path(monkeypatch) -> None:
    class FakeAgent:
        def invoke(
            self, payload: dict[str, object], config: dict[str, object] | None = None
        ) -> dict[str, object]:
            assert payload == {"messages": "hello"}
            assert config is not None
            return {"messages": [{"role": "assistant", "content": "hi"}]}

    monkeypatch.setattr(
        "urgs_deepagents_service.main.build_chat_model", lambda settings, model: object()
    )
    monkeypatch.setattr(
        "urgs_deepagents_service.runtime.create_deep_agent", lambda **kwargs: FakeAgent()
    )

    client = TestClient(app)
    response = client.post("/v1/agents/invoke", json={"messages": "hello"})

    assert response.status_code == 200
    assert response.json()["output"]["messages"][0]["content"] == "hi"


def test_agents_stream_sse_schema(monkeypatch) -> None:
    class FakeAgent:
        async def astream_events(
            self,
            payload: dict[str, object],
            config: dict[str, object] | None = None,
            version: str = "v2",
        ):
            assert payload == {"messages": "hello"}
            assert config is not None
            assert version == "v2"
            yield {
                "event": "on_chat_model_stream",
                "name": "model",
                "data": {"chunk": SimpleNamespace(content="hi")},
            }

    monkeypatch.setattr(
        "urgs_deepagents_service.main.build_chat_model", lambda settings, model: object()
    )
    monkeypatch.setattr(
        "urgs_deepagents_service.runtime.create_deep_agent", lambda **kwargs: FakeAgent()
    )

    client = TestClient(app)
    with client.stream("POST", "/v1/agents/stream", json={"messages": "hello"}) as response:
        raw = "".join(response.iter_text())

    assert response.status_code == 200
    events = _parse_sse(raw)
    names = [name for name, _ in events]
    assert names == ["agent", "content", "done"]
    run_ids = {data["run_id"] for _, data in events}
    assert len(run_ids) == 1
    for name, data in events:
        assert data["event"] == name
        assert data["step_id"]
        assert data["timestamp"]
        assert data["status"]
        assert data["message"]
    assert events[1][1]["content"] == "hi"


def test_router_route_does_not_use_response_format_tool_choice(monkeypatch) -> None:
    captured_kwargs: dict[str, object] = {}

    class FakeRouter:
        def invoke(self, payload: dict[str, object]) -> dict[str, object]:
            return {
                "messages": [
                    {
                        "type": "ai",
                        "content": (
                            '{"agent_code":"general-agent","confidence":0.8,'
                            '"reason":"no specialist fits","task_type":"general",'
                            '"requires_collaboration":false,"collaboration_plan":""}'
                        ),
                    }
                ]
            }

    def fake_create_deep_agent(**kwargs: object) -> FakeRouter:
        captured_kwargs.update(kwargs)
        return FakeRouter()

    monkeypatch.setattr(
        "urgs_deepagents_service.main.build_chat_model", lambda settings, model: object()
    )
    monkeypatch.setattr("urgs_deepagents_service.runtime.create_deep_agent", fake_create_deep_agent)

    client = TestClient(app)
    response = client.post(
        "/v1/router/route",
        json={
            "message": "随便问一个问题",
            "agents": [
                {
                    "agent_code": "general-agent",
                    "agent_name": "通用助手",
                    "agent_type": "GENERAL",
                    "description": "General fallback agent",
                }
            ],
        },
    )

    assert response.status_code == 200
    assert response.json()["agent_code"] == "general-agent"
    assert "response_format" not in captured_kwargs


def test_parse_default_config_strips_chat_completions_suffix() -> None:
    config = _parse_default_config(
        {
            "provider": "custom",
            "model": "qwen3",
            "endpoint": "http://127.0.0.1:11434/v1/chat/completions",
            "apiKey": "sk-test",
            "maxTokens": 2048,
            "temperature": 0.2,
        }
    )

    assert config.model == "qwen3"
    assert config.endpoint == "http://127.0.0.1:11434/v1"


def test_build_chat_model_uses_ai_api_default(monkeypatch) -> None:
    class FakeSettings:
        urgs_api_url = "http://127.0.0.1:8080"
        internal_api_token = "internal-token"
        internal_api_auth_header = "Authorization"
        internal_api_auth_prefix = "Bearer "
        config_request_timeout_seconds = 10.0

    class FakeResponse:
        def raise_for_status(self) -> None:
            return None

        def json(self) -> dict[str, object]:
            return {
                "provider": "custom",
                "model": "qwen3",
                "endpoint": "http://127.0.0.1:11434/v1",
                "apiKey": "sk-test",
                "maxTokens": 2048,
                "temperature": 0.2,
            }

    def fake_get(url: str, headers: dict[str, str], timeout: float) -> FakeResponse:
        assert url == "http://127.0.0.1:8080/api/internal/ai/config/default"
        assert headers == {"Authorization": "Bearer internal-token"}
        assert timeout == 10.0
        return FakeResponse()

    monkeypatch.setattr("urgs_deepagents_service.model_config.httpx.get", fake_get)

    model = build_chat_model(FakeSettings(), None)  # type: ignore[arg-type]

    assert isinstance(model, ChatOpenAI)
    assert model.model_name == "qwen3"
