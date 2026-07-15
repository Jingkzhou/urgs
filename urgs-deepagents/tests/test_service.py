import json
from datetime import date
from types import SimpleNamespace

import httpx
import pytest
from fastapi import HTTPException
from fastapi.testclient import TestClient
from langchain.agents import create_agent
from langchain.agents.middleware import ToolCallLimitMiddleware
from langchain_core.language_models.fake_chat_models import FakeMessagesListChatModel
from langchain_core.messages import AIMessage, AIMessageChunk, HumanMessage, ToolMessage
from langchain_core.tools import tool
from langchain_openai import ChatOpenAI

from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.main import (
    DEFAULT_EXCLUDED_TOOLS,
    READ_ONLY_FILESYSTEM_PERMISSIONS,
    ToolVisibilityMiddleware,
    _agent_runtime_kwargs,
    app,
    create_app,
)
from urgs_deepagents_service.model_config import (
    ReasoningContentChatOpenAI,
    _parse_default_config,
    build_chat_model,
    load_default_ai_config,
)
from urgs_deepagents_service.orchestrator.progress import PROGRESS_TOOL_NAME
from urgs_deepagents_service.runtime import (
    REGULATORY_KNOWLEDGE_AGENT_CODE,
    REGULATORY_KNOWLEDGE_MIN_RECURSION_LIMIT,
    REGULATORY_KNOWLEDGE_TOOL_CALL_HARD_LIMIT,
    BusinessToolCallLimitMiddleware,
    BusinessToolLoopDetectionMiddleware,
    RegulatoryCodeEvidenceMiddleware,
    RegulatoryRetrievalGateMiddleware,
    _runtime_date_context,
    agent_graph_config,
    create_runtime_agent,
    graph_config,
)
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
    assert response.headers["X-Request-ID"]


def test_runtime_date_context_resolves_relative_year_from_explicit_date() -> None:
    context = _runtime_date_context(date(2026, 7, 15))

    assert "当前日期：2026-07-15" in context
    assert "‘今年’‘本年’指 2026 年" in context
    assert "不得沿用训练数据年份" in context


def test_health_ready_up(monkeypatch) -> None:
    monkeypatch.setattr(
        "urgs_deepagents_service.main.check_model_config_ready",
        lambda settings: {"status": "UP", "source": "DEEPAGENTS_MODEL", "model": "openai:gpt-4.1"},
    )
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 200
    body = response.json()
    assert body["status"] == "UP"
    assert body["dependencies"]["model_config"]["source"] == "DEEPAGENTS_MODEL"


def test_health_ready_down(monkeypatch) -> None:
    monkeypatch.setattr(
        "urgs_deepagents_service.main.check_model_config_ready",
        lambda settings: {"status": "DOWN", "source": "urgs-api", "reason": "missing token"},
    )
    client = TestClient(app)

    response = client.get("/health/ready")

    assert response.status_code == 503
    assert response.json()["status"] == "DOWN"


def test_internal_auth_required_when_token_configured(monkeypatch) -> None:
    monkeypatch.setenv("DEEPAGENTS_INTERNAL_API_TOKEN", "test-token")
    get_settings.cache_clear()
    try:
        secured_app = create_app()
        client = TestClient(secured_app)

        live_response = client.get("/health/live")
        unauthorized = client.post("/v1/agents/invoke", json={"messages": "hello"})

        assert live_response.status_code == 200
        assert unauthorized.status_code == 401
    finally:
        get_settings.cache_clear()


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


def test_regulatory_knowledge_agent_uses_loop_detection_and_global_circuit_breaker(
    tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    class FakeSettings:
        workspace_root = str(tmp_path)
        memory_files = ""
        skill_dirs = ""
        enable_write_tools = False
        skills_root = str(tmp_path / "skills")

    captured: dict[str, object] = {}
    monkeypatch.setattr(
        "urgs_deepagents_service.runtime.create_deep_agent",
        lambda **kwargs: captured.update(kwargs) or kwargs,
    )

    create_runtime_agent(
        model=object(),
        settings=FakeSettings(),
        system_prompt="只读监管查询",
        memory_files="/AGENTS.md",
        skill_dirs=None,
        tool_allowlist="ls,read_file,glob,grep",
        allow_write=False,
        workspace_root=str(tmp_path),
        debug=False,
        agent_code=REGULATORY_KNOWLEDGE_AGENT_CODE,
    )

    limiter = next(
        item for item in captured["middleware"] if isinstance(item, ToolCallLimitMiddleware)
    )
    assert any(
        isinstance(item, RegulatoryCodeEvidenceMiddleware) for item in captured["middleware"]
    )
    assert any(
        isinstance(item, RegulatoryRetrievalGateMiddleware) for item in captured["middleware"]
    )
    loop_detector = next(
        item
        for item in captured["middleware"]
        if isinstance(item, BusinessToolLoopDetectionMiddleware)
    )
    assert limiter.run_limit == REGULATORY_KNOWLEDGE_TOOL_CALL_HARD_LIMIT
    assert limiter.exit_behavior == "continue"
    assert isinstance(limiter, BusinessToolCallLimitMiddleware)
    assert not limiter._matches_tool_filter({"name": PROGRESS_TOOL_NAME})
    assert limiter._matches_tool_filter({"name": "read_file"})
    assert loop_detector.warning_threshold < loop_detector.critical_threshold
    assert "不使用固定 8 次" in captured["system_prompt"]
    assert "异常熔断上限" in captured["system_prompt"]
    assert "不得为了穷举所有可能性逐页遍历" in captured["system_prompt"]
    assert "不得把单笔贷款金额、贷款余额等同于单户授信总额" in captured["system_prompt"]


def test_regulatory_graph_depth_covers_hard_tool_budget() -> None:
    class FakeSettings:
        recursion_limit = 100

    assert agent_graph_config(FakeSettings(), REGULATORY_KNOWLEDGE_AGENT_CODE) == {
        "recursion_limit": REGULATORY_KNOWLEDGE_MIN_RECURSION_LIMIT
    }
    assert agent_graph_config(FakeSettings(), "general-agent") == {"recursion_limit": 100}


def _tool_round(index: int, *, result: str = "same") -> list[object]:
    call_id = f"call-{index}"
    return [
        AIMessage(
            content="",
            tool_calls=[
                {
                    "name": "grep",
                    "args": {"pattern": "福费廷", "path": "/03-实体"},
                    "id": call_id,
                    "type": "tool_call",
                }
            ],
        ),
        ToolMessage(content=result, tool_call_id=call_id, status="success"),
    ]


def test_tool_loop_detection_blocks_repeated_identical_no_progress_calls() -> None:
    middleware = BusinessToolLoopDetectionMiddleware(warning_threshold=2, critical_threshold=4)
    messages: list[object] = []
    for index in range(3):
        messages.extend(_tool_round(index))
    messages.append(
        AIMessage(
            content="",
            tool_calls=[
                {
                    "name": "grep",
                    "args": {"pattern": "福费廷", "path": "/03-实体"},
                    "id": "call-blocked",
                    "type": "tool_call",
                }
            ],
        )
    )

    update = middleware.after_model({"messages": messages}, None)

    assert update is not None
    blocked = update["messages"][0]
    assert isinstance(blocked, ToolMessage)
    assert blocked.status == "error"
    assert "无进展" in str(blocked.content)


def test_tool_loop_detection_allows_repeated_calls_when_results_change() -> None:
    middleware = BusinessToolLoopDetectionMiddleware(warning_threshold=2, critical_threshold=4)
    messages: list[object] = []
    for index in range(3):
        messages.extend(_tool_round(index, result=f"page-{index}"))
    messages.append(
        AIMessage(
            content="",
            tool_calls=[
                {
                    "name": "grep",
                    "args": {"pattern": "福费廷", "path": "/03-实体"},
                    "id": "call-allowed",
                    "type": "tool_call",
                }
            ],
        )
    )

    assert middleware.after_model({"messages": messages}, None) is None


def test_tool_loop_detection_returns_control_to_model_after_blocking() -> None:
    class ToolAwareFake(FakeMessagesListChatModel):
        def bind_tools(self, tools, *, tool_choice=None, **kwargs):
            return self

    @tool
    def lookup(query: str) -> str:
        """Return a stable lookup result."""

        return "same"

    def lookup_call(index: int) -> AIMessage:
        return AIMessage(
            content="",
            tool_calls=[
                {
                    "name": "lookup",
                    "args": {"query": "福费廷"},
                    "id": f"lookup-{index}",
                    "type": "tool_call",
                }
            ],
        )

    model = ToolAwareFake(
        responses=[
            lookup_call(1),
            lookup_call(2),
            lookup_call(3),
            AIMessage(content="已调整检索策略并形成最终答案"),
        ]
    )
    agent = create_agent(
        model,
        tools=[lookup],
        middleware=[
            BusinessToolLoopDetectionMiddleware(warning_threshold=2, critical_threshold=3)
        ],
    )

    result = agent.invoke({"messages": [{"role": "user", "content": "查询福费廷"}]})

    assert result["messages"][-1].content == "已调整检索策略并形成最终答案"
    assert any(
        isinstance(message, ToolMessage)
        and message.status == "error"
        and "无进展" in str(message.content)
        for message in result["messages"]
    )


def test_runtime_agent_injects_public_progress_tool(
    tmp_path, monkeypatch: pytest.MonkeyPatch
) -> None:
    class FakeSettings:
        workspace_root = str(tmp_path)
        memory_files = ""
        skill_dirs = ""
        enable_write_tools = False

    captured: dict[str, object] = {}
    monkeypatch.setattr(
        "urgs_deepagents_service.runtime.create_deep_agent",
        lambda **kwargs: captured.update(kwargs) or kwargs,
    )

    create_runtime_agent(
        model=object(),
        settings=FakeSettings(),
        system_prompt="执行用户任务",
        memory_files=None,
        skill_dirs=None,
        tool_allowlist="read_file,grep",
        workspace_root=str(tmp_path),
        debug=False,
    )

    tool_names = {tool.name for tool in captured["tools"]}
    visibility = next(
        item for item in captured["middleware"] if isinstance(item, ToolVisibilityMiddleware)
    )
    assert PROGRESS_TOOL_NAME in tool_names
    assert visibility.allowed == frozenset({"read_file", "grep", PROGRESS_TOOL_NAME})
    assert "不要逐条复述工具调用" in captured["system_prompt"]


def test_regulatory_code_evidence_middleware_removes_unsupported_exact_codes() -> None:
    middleware = RegulatoryCodeEvidenceMiddleware()
    supported = ToolMessage(
        content="已核验 G01、G21 和 T_6.1。",
        tool_call_id="tool-1",
        status="success",
    )
    answer = AIMessage(
        content="涉及 G01、G21、T_6.1、T_5.1、T_6.x、JS_203 和 A1413。",
        id="answer-1",
    )

    update = middleware.after_model({"messages": [supported, answer]}, None)

    assert update is not None
    sanitized = update["messages"][0]
    assert sanitized.id == "answer-1"
    assert "G01" in sanitized.content
    assert "G21" in sanitized.content
    assert "T_6.1" in sanitized.content
    assert "T_5.1" not in sanitized.content
    assert "T_6.x" not in sanitized.content
    assert "JS_203" not in sanitized.content
    assert "A1413" not in sanitized.content
    assert "未在本轮检索证据中出现" in sanitized.content


def test_regulatory_code_evidence_middleware_keeps_fully_supported_answer() -> None:
    middleware = RegulatoryCodeEvidenceMiddleware()
    supported = ToolMessage(content="G01 和 G21", tool_call_id="tool-1", status="success")
    answer = AIMessage(content="涉及 G01 和 G21。", id="answer-1")

    assert middleware.after_model({"messages": [supported, answer]}, None) is None


def test_regulatory_retrieval_gate_forces_required_evidence_sequence() -> None:
    middleware = RegulatoryRetrievalGateMiddleware()
    question = HumanMessage(
        content="分析同业存放业务变更影响哪些监管系统、报表和监管指标，并说明排除依据"
    )
    answer = AIMessage(content="直接给出结论", id="answer-1")

    update = middleware.after_model({"messages": [question, answer]}, None)

    assert update is not None
    assert update["jump_to"] == "tools"
    first_call = update["messages"][0].tool_calls[0]
    assert first_call["name"] == "read_file"
    assert first_call["args"]["file_path"] == "/04-综合/监管业务场景-报送映射.md"

    completed_calls = [
        AIMessage(content="", tool_calls=[first_call]),
        ToolMessage(content="场景映射", tool_call_id=first_call["id"]),
    ]
    update = middleware.after_model(
        {"messages": [question, *completed_calls, AIMessage(content="准备结束")]}, None
    )

    assert update is not None
    second_call = update["messages"][0].tool_calls[0]
    assert second_call["name"] == "grep"
    assert second_call["args"]["pattern"] == "同业存放"


def test_regulatory_retrieval_gate_skips_simple_fact_question() -> None:
    middleware = RegulatoryRetrievalGateMiddleware()
    messages = [HumanMessage(content="G01 的报送频度是什么"), AIMessage(content="月报")]

    assert middleware.after_model({"messages": messages}, None) is None


def test_regulatory_retrieval_gate_executes_tools_and_terminates(tmp_path) -> None:
    for relative_path in (
        "04-综合/监管业务场景-报送映射.md",
        "02-主题/同业存放-监管报送映射.md",
        "03-实体/EAST5.0-IE_004_405-对公存款分户账.md",
    ):
        path = tmp_path / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text("同业存放 EAST5.0 IE_004_405", encoding="utf-8")

    class ToolAwareFake(FakeMessagesListChatModel):
        def bind_tools(self, tools, *, tool_choice=None, **kwargs):
            return self

    class FakeSettings:
        memory_files = ""
        skill_dirs = ""
        workspace_root = str(tmp_path)
        enable_write_tools = False
        skills_root = str(tmp_path / "skills")
        recursion_limit = 100

    model = ToolAwareFake(responses=[AIMessage(content="最终答案") for _ in range(8)])
    agent = create_runtime_agent(
        model=model,
        settings=FakeSettings(),
        system_prompt="只读监管助手",
        memory_files=None,
        skill_dirs=None,
        tool_allowlist="ls,read_file,glob,grep",
        workspace_root=str(tmp_path),
        debug=False,
        agent_code=REGULATORY_KNOWLEDGE_AGENT_CODE,
    )

    result = agent.invoke(
        {
            "messages": (
                "分析同业存放业务变更影响哪些监管系统、报表和监管指标，并说明排除依据"
            )
        },
        config=graph_config(FakeSettings()),
    )
    calls = [
        call
        for message in result["messages"]
        for call in (getattr(message, "tool_calls", None) or [])
    ]

    assert [call["name"] for call in calls] == [
        "read_file",
        "grep",
        "read_file",
        "read_file",
    ]
    assert result["messages"][-1].content == "最终答案"


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
        async def ainvoke(self, payload: dict[str, object]) -> dict[str, object]:
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


def test_router_route_reuses_data_query_agent_for_catalog_followup(monkeypatch) -> None:
    monkeypatch.setattr(
        "urgs_deepagents_service.main.build_chat_model", lambda settings, model: object()
    )

    client = TestClient(app)
    response = client.post(
        "/v1/router/route",
        json={
            "message": "都能查哪些指标？",
            "current_agent_code": "regulatory-data-query-agent",
            "conversation_context": "用户：查询各项存款。\n助手：当前目录未找到匹配指标。",
            "agents": [
                {
                    "agent_code": "regulatory-data-query-agent",
                    "agent_name": "监管指标数据查询助手",
                    "agent_type": "SPECIALIST",
                },
                {
                    "agent_code": "regulatory-knowledge-agent",
                    "agent_name": "监管助手",
                    "agent_type": "SPECIALIST",
                },
            ],
        },
    )

    assert response.status_code == 200
    assert response.json()["agent_code"] == "regulatory-data-query-agent"
    assert response.json()["reused_current_agent"] is True


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


def test_reasoning_content_is_preserved_across_tool_call_rounds() -> None:
    model = ReasoningContentChatOpenAI(
        model="deepseek-reasoner",
        api_key="sk-test",
        base_url="https://api.deepseek.com/v1",
    )
    chunk = {
        "choices": [
            {
                "delta": {"role": "assistant", "reasoning_content": "分析过程"},
                "finish_reason": None,
            }
        ]
    }

    generation = model._convert_chunk_to_generation_chunk(chunk, AIMessageChunk, None)

    assert generation is not None
    assert generation.message.additional_kwargs["reasoning_content"] == "分析过程"

    assistant = AIMessage(
        content="",
        additional_kwargs={"reasoning_content": "分析过程"},
        tool_calls=[
            {
                "name": "read_file",
                "args": {"file_path": "/example.md"},
                "id": "call-1",
                "type": "tool_call",
            }
        ],
    )
    payload = model._get_request_payload(
        [assistant, ToolMessage(content="文件内容", tool_call_id="call-1")]
    )

    assert payload["messages"][0]["reasoning_content"] == "分析过程"


def test_load_default_ai_config_retries_transient_http_errors(monkeypatch) -> None:
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

    calls = {"count": 0}

    def fake_get(url: str, headers: dict[str, str], timeout: float) -> FakeResponse:
        calls["count"] += 1
        if calls["count"] == 1:
            raise httpx.ConnectError("temporary")
        return FakeResponse()

    monkeypatch.setattr("urgs_deepagents_service.model_config.httpx.get", fake_get)

    config = load_default_ai_config(FakeSettings())  # type: ignore[arg-type]

    assert calls["count"] == 2
    assert config.model == "qwen3"


def test_load_default_ai_config_failure_is_sanitized(monkeypatch) -> None:
    class FakeSettings:
        urgs_api_url = "http://127.0.0.1:8080"
        internal_api_token = "internal-token"
        internal_api_auth_header = "Authorization"
        internal_api_auth_prefix = "Bearer "
        config_request_timeout_seconds = 10.0

    def fake_get(url: str, headers: dict[str, str], timeout: float) -> object:
        raise httpx.ConnectError("token=secret sk-secret123 http://127.0.0.1:8080")

    monkeypatch.setattr("urgs_deepagents_service.model_config.httpx.get", fake_get)

    with pytest.raises(HTTPException) as exc_info:
        load_default_ai_config(FakeSettings())  # type: ignore[arg-type]

    detail = str(exc_info.value.detail)
    assert "secret" not in detail
    assert "127.0.0.1" not in detail
    assert "ConnectError" in detail
