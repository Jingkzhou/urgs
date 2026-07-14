"""编排模块单测：通过 monkeypatch 替换模型调用与各阶段，验证编排流程与 SSE 事件。"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
from types import SimpleNamespace
from typing import Any

import pytest

from urgs_deepagents_service.orchestrator import (
    finalizer as finalizer_mod,
)
from urgs_deepagents_service.orchestrator import (
    input_guard as guard_mod,
)
from urgs_deepagents_service.orchestrator import (
    planner as planner_mod,
)
from urgs_deepagents_service.orchestrator import (
    reviewer as reviewer_mod,
)
from urgs_deepagents_service.orchestrator import (
    router as router_mod,
)
from urgs_deepagents_service.orchestrator import stream_orchestration
from urgs_deepagents_service.orchestrator import (
    worker as worker_mod,
)
from urgs_deepagents_service.orchestrator.orchestrator import _conversation_context
from urgs_deepagents_service.orchestrator.progress import (
    PROGRESS_TOOL_NAME,
    build_tool_progress_payload,
)
from urgs_deepagents_service.orchestrator.state import (
    GuardResult,
    PlanStep,
    ReviewResult,
    RoutingResult,
    WorkerOutput,
)
from urgs_deepagents_service.orchestrator.task_policy import (
    explicitly_requests_workspace_access,
    should_answer_directly,
)
from urgs_deepagents_service.regulatory_coverage import (
    requires_regulatory_coverage_review,
)
from urgs_deepagents_service.schemas import (
    AgentRuntimeConfig,
    OrchestratorRequest,
    RouterAgentDescriptor,
)


class _FakeSettings:
    memory_files = ""
    skill_dirs = ""
    workspace_root = None
    model = None


def _agents() -> list[RouterAgentDescriptor]:
    return [
        RouterAgentDescriptor(
            agent_code="general-agent",
            agent_name="通用助手",
            agent_type="GENERAL",
            build_mode="DEEPAGENTS",
            description="通用",
        ),
        RouterAgentDescriptor(
            agent_code="lineage-agent",
            agent_name="血缘助手",
            agent_type="SPECIALIST",
            build_mode="DEEPAGENTS",
            description="血缘分析",
        ),
        RouterAgentDescriptor(
            agent_code="rag-agent",
            agent_name="RAG助手",
            agent_type="SPECIALIST",
            build_mode="RAG",
            description="知识库问答",
        ),
    ]


def _configs() -> dict[str, AgentRuntimeConfig]:
    return {
        "general-agent": AgentRuntimeConfig(system_prompt="你是通用助手"),
        "lineage-agent": AgentRuntimeConfig(system_prompt="你是血缘助手"),
    }


async def _collect(stream: AsyncIterator[str]) -> list[tuple[str, Any]]:
    out: list[tuple[str, Any]] = []
    async for raw in stream:
        assert raw.startswith("event: ")
        name = raw[len("event: ") : raw.index("\n")].strip()
        data_line = raw.split("data: ", 1)[1].strip()
        out.append((name, json.loads(data_line)))
    return out


async def _make_stream(monkeypatch, request: OrchestratorRequest) -> list[tuple[str, Any]]:
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.build_chat_model",
        lambda settings, model: object(),
    )
    return await _collect(stream_orchestration(request, _FakeSettings()))


def _assert_envelope(events: list[tuple[str, Any]]) -> str:
    assert events
    run_ids = {data["run_id"] for _, data in events}
    assert len(run_ids) == 1
    run_id = next(iter(run_ids))
    for name, data in events:
        assert data["event"] == name
        assert data["type"]
        assert data["run_id"] == run_id
        assert data["step_id"]
        assert "agent_code" in data
        assert data["timestamp"].endswith("Z")
        assert data["status"]
        assert data["message"]
    return run_id


def _assert_subsequence(names: list[str], expected: list[str]) -> None:
    cursor = 0
    for name in names:
        if cursor < len(expected) and name == expected[cursor]:
            cursor += 1
    assert cursor == len(expected)


def test_general_agent_answers_code_example_without_workspace_tools() -> None:
    assert should_answer_directly(
        "general-agent",
        "使用 React 实现一个深色模式切换功能。",
    )
    assert should_answer_directly(
        "general-agent",
        "说明如何在 React 代码中实现深色模式切换。",
    )
    assert not explicitly_requests_workspace_access("使用 React 实现一个深色模式切换功能。")


def test_general_agent_uses_workspace_only_when_user_explicitly_requests_it() -> None:
    assert not should_answer_directly(
        "general-agent",
        "请在 urgs-web/src/App.tsx 中实现深色模式切换。",
    )
    assert not should_answer_directly(
        "general-agent",
        "修改吧",
        "用户：请检查当前项目中的主题实现。",
    )
    assert should_answer_directly(
        "general-agent",
        "只做解答，不要扫描项目。",
        "用户：请检查当前项目中的主题实现。",
    )
    assert not should_answer_directly(
        "lineage-agent",
        "解释这段 SQL 的血缘。",
    )


def _patch_guard(monkeypatch, passed: bool, reason: str = "") -> None:
    async def fake_guard(model: Any, user_message: str) -> GuardResult:
        return GuardResult(passed=passed, reason=reason, category="" if passed else "injection")

    monkeypatch.setattr(guard_mod, "run_input_guard", fake_guard)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_input_guard", fake_guard
    )


def _patch_router(monkeypatch, agent_code: str, is_complex: bool) -> None:
    async def fake_router(
        model: Any,
        user_message: str,
        agents: Any,
        current_agent_code: str | None = None,
        conversation_context: str = "",
    ) -> RoutingResult:
        return RoutingResult(
            agent_code=agent_code,
            confidence=0.9,
            reason="test",
            task_type="test",
            is_complex=is_complex,
            reused_current_agent=agent_code == current_agent_code,
        )

    monkeypatch.setattr(router_mod, "run_router", fake_router)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_router", fake_router)


def _patch_planner(monkeypatch, steps: list[tuple[str, str]]) -> None:
    async def fake_planner(
        model: Any, user_message: str, candidate_agents: list[str]
    ) -> list[PlanStep]:
        return [
            PlanStep(step=i + 1, agent=agent, task=task, depends_on=[] if i == 0 else [i])
            for i, (agent, task) in enumerate(steps)
        ]

    monkeypatch.setattr(planner_mod, "run_planner", fake_planner)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_planner", fake_planner
    )


def _patch_review(monkeypatch, passed: bool, reason: str = "ok") -> None:
    async def fake_review(
        model: Any, user_message: str, outputs: list[WorkerOutput]
    ) -> ReviewResult:
        return ReviewResult(passed=passed, score=0.9 if passed else 0.3, reason=reason, issues=[])

    async def fake_review_fb(
        model: Any, user_message: str, outputs: list[WorkerOutput], feedback: str
    ) -> ReviewResult:
        return ReviewResult(passed=passed, score=0.9 if passed else 0.3, reason=reason, issues=[])

    monkeypatch.setattr(reviewer_mod, "run_review", fake_review)
    monkeypatch.setattr(reviewer_mod, "run_review_with_feedback", fake_review_fb)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_review", fake_review)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_review_with_feedback", fake_review_fb
    )


def test_reviewer_prompt_accepts_required_clarification() -> None:
    assert "缺少必填输入" in reviewer_mod.REVIEWER_SYSTEM_PROMPT
    assert "不得要求 Worker 使用空条件" in reviewer_mod.REVIEWER_SYSTEM_PROMPT
    assert "不得自行增加" in reviewer_mod.REVIEWER_SYSTEM_PROMPT
    assert "不得强制要求继续读取或摘录原文页" in reviewer_mod.REVIEWER_SYSTEM_PROMPT


def test_finalizer_prompt_hides_review_internals() -> None:
    prompt = finalizer_mod._build_system_prompt(
        quality_risk=True,
        review=ReviewResult(
            passed=False,
            score=0.2,
            reason="验收未通过",
            issues=["不应展示的问题"],
            required_fixes=["不应展示的修复项"],
        ),
    )
    assert "不应展示的问题" not in prompt
    assert "不应展示的修复项" not in prompt
    assert "不要向用户输出 Reviewer" in prompt
    assert "不要再次验证" in prompt
    assert "禁止输出“让我先”" in prompt


def test_conversation_context_excludes_current_turn_and_keeps_prior_slots() -> None:
    context = _conversation_context(
        [
            {"role": "user", "content": "查各项贷款余额"},
            {"role": "assistant", "content": "请提供日期和机构"},
            {"role": "user", "content": "1200机构 2026-02-28"},
        ],
        "1200机构 2026-02-28",
    )
    assert "查各项贷款余额" in context
    assert "请提供日期和机构" in context
    assert "用户：1200机构 2026-02-28" not in context


@pytest.mark.asyncio
async def test_worker_merges_context_and_current_slot_completion(monkeypatch) -> None:
    captured: dict[str, Any] = {}

    class FakeAgent:
        async def astream_events(
            self,
            payload: dict[str, object],
            config: dict[str, object] | None = None,
            version: str = "v2",
        ) -> AsyncIterator[dict[str, object]]:
            captured["messages"] = payload["messages"]
            yield {
                "event": "on_tool_start",
                "name": "query_regulatory_summary",
                "run_id": "tool-1",
                "data": {
                    "input": {
                        "system_code": "URGS",
                        "table_code": "g01_2",
                        "indicator_codes": ["g01_2_1_c"],
                        "organization": "1100",
                    }
                },
            }
            yield {
                "event": "on_tool_end",
                "name": "query_regulatory_summary",
                "run_id": "tool-1",
                "data": {
                    "output": {
                        "content": (
                            '{"ok": true, "returned_count": 1, '
                            '"rows": [{"metric_value": "100.00"}]}'
                        )
                    }
                },
            }
            yield {
                "event": "on_chat_model_end",
                "name": "model",
                "data": {"output": SimpleNamespace(content="ok")},
            }

    monkeypatch.setattr(worker_mod, "create_runtime_agent", lambda **kwargs: FakeAgent())
    run = await worker_mod.run_worker(
        model=object(),
        settings=_FakeSettings(),
        agent_code="regulatory-data-query-agent",
        agent_config=AgentRuntimeConfig(system_prompt="监管查询"),
        task="总行 2月末",
        context="历史对话中已确认的信息，必须优先继承，不要重复询问：\n用户：帮我查一下1各项贷款.本外币合计数据\n助手：指标：1各项贷款.本外币合计（编码：g01_2_1_c）；可用统计期间：2026-01-31、2026-02-28",
        stream_content=False,
        debug=False,
    )

    events = await _collect(run.events())

    messages = captured["messages"]
    assert len(messages) == 1
    content = messages[0]["content"]
    assert "当前用户补充" in content
    assert "总行 2月末" in content
    assert "g01_2_1_c" in content
    assert "必须继承" in content
    assert run.output.tool_results[0]["tool_name"] == "query_regulatory_summary"
    assert run.output.tool_results[0]["args"]["organization"] == "1100"
    assert "metric_value" in run.output.tool_results[0]["result"]
    fallback_progress = [
        data for name, data in events if name == "agent" and data["type"] == "progress"
    ]
    assert fallback_progress[-1]["title"] == "query_regulatory_summary 已完成"


async def test_worker_converts_progress_tool_into_public_event(monkeypatch) -> None:
    class FakeAgent:
        async def astream_events(
            self,
            payload: dict[str, object],
            config: dict[str, object] | None = None,
            version: str = "v2",
        ) -> AsyncIterator[dict[str, object]]:
            yield {
                "event": "on_tool_start",
                "name": PROGRESS_TOOL_NAME,
                "run_id": "progress-1",
                "data": {
                    "input": {
                        "title": "已定位检索范围",
                        "content": "已确认需要优先核对用户点名的报表。",
                        "next_action": "读取对应知识页",
                        "phase": "verification",
                    }
                },
            }
            yield {
                "event": "on_tool_end",
                "name": PROGRESS_TOOL_NAME,
                "run_id": "progress-1",
                "data": {"output": "进度已记录"},
            }
            yield {
                "event": "on_chat_model_end",
                "name": "model",
                "data": {"output": SimpleNamespace(content="最终业务答案")},
            }

    monkeypatch.setattr(worker_mod, "create_runtime_agent", lambda **kwargs: FakeAgent())
    run = await worker_mod.run_worker(
        model=object(),
        settings=_FakeSettings(),
        agent_code="general-agent",
        agent_config=AgentRuntimeConfig(system_prompt="通用助手"),
        task="分析问题",
        context="",
        stream_content=False,
        debug=False,
    )

    events = await _collect(run.events())
    progress_events = [
        data for name, data in events if name == "agent" and data["type"] == "progress"
    ]
    assert len(progress_events) == 1
    assert progress_events[0]["title"] == "已定位检索范围"
    assert progress_events[0]["next_action"] == "读取对应知识页"
    assert progress_events[0]["phase"] == "verification"
    assert run.output.answer == "最终业务答案"
    assert run.output.tool_results == []


async def test_worker_direct_answer_uses_no_tools_control_agent(monkeypatch) -> None:
    captured: dict[str, Any] = {}

    class FakeAgent:
        async def astream_events(
            self,
            payload: dict[str, object],
            config: dict[str, object] | None = None,
            version: str = "v2",
        ) -> AsyncIterator[dict[str, object]]:
            yield {
                "event": "on_chat_model_end",
                "name": "model",
                "data": {"output": SimpleNamespace(content="直接答案")},
            }

    def fake_create_control_agent(**kwargs: Any) -> FakeAgent:
        captured.update(kwargs)
        return FakeAgent()

    monkeypatch.setattr(worker_mod, "create_control_agent", fake_create_control_agent)
    monkeypatch.setattr(
        worker_mod,
        "create_runtime_agent",
        lambda **kwargs: pytest.fail("直接解答不应创建带工具的 Runtime Agent"),
    )
    run = await worker_mod.run_worker(
        model=object(),
        settings=_FakeSettings(),
        agent_code="general-agent",
        agent_config=AgentRuntimeConfig(
            system_prompt="你是通用助手",
            memory_files="/AGENTS.md",
            tool_allowlist="ls,read_file,glob,grep",
            workspace_root="/workspace",
        ),
        task="使用 React 实现一个深色模式切换功能。",
        context="",
        stream_content=True,
        debug=False,
        direct_answer=True,
    )

    events = await _collect(run.events())

    assert "本次请求没有授权访问工作区" in captured["system_prompt"]
    assert "task、ls、read_file、glob、grep" in captured["system_prompt"]
    assert [name for name, _ in events if name == "content"] == ["content"]
    assert not [data for name, data in events if name == "agent" and "toolName" in data]
    assert run.output.answer == "直接答案"


def test_tool_progress_reports_grep_match_and_empty_result() -> None:
    matched = build_tool_progress_payload(
        "grep",
        {"pattern": "同业存放", "path": "02-主题/04-综合"},
        "02-主题/04-综合/同业业务.md",
    )
    missing = build_tool_progress_payload(
        "grep",
        {"pattern": "不存在指标", "path": "02-主题"},
        "No matches found",
    )

    assert matched["title"] == "已定位“同业存放”相关内容"
    assert matched["phase"] == "verification"
    assert "读取具体文件" in matched["content"]
    assert missing["title"] == "未找到“不存在指标”的直接匹配"
    assert missing["phase"] == "adjustment"


def test_tool_progress_sanitizes_sensitive_values() -> None:
    progress = build_tool_progress_payload(
        "read_file",
        {"file_path": "https://127.0.0.1:8003/private?token=secret-value"},
        "ok",
    )

    assert "127.0.0.1" not in progress["title"]
    assert "secret-value" not in progress["title"]


def test_rework_feedback_includes_tool_results_as_evidence() -> None:
    feedback = reviewer_mod.build_rework_feedback(
        ReviewResult(
            passed=False,
            score=0.5,
            reason="答案未使用工具结果",
            issues=["缺少查询值"],
            required_fixes=["基于工具结果返回数值"],
        ),
        [
            WorkerOutput(
                agent_code="regulatory-data-query-agent",
                task="2026年2月末",
                answer="请确认指标",
                tool_results=[
                    {
                        "tool_name": "query_regulatory_summary",
                        "args": {
                            "system_code": "URGS",
                            "table_code": "g01_2",
                            "indicator_codes": ["g01_2_1_c"],
                            "organization": "1100",
                        },
                        "result": (
                            '{"ok": true, "returned_count": 1, '
                            '"rows": [{"metric_value": "100.00"}]}'
                        ),
                    }
                ],
            )
        ],
    )
    assert "工具调用结果" in feedback
    assert "metric_value" in feedback
    assert "不要重复询问工具入参" in feedback


def _patch_worker(monkeypatch, answer: str = "worker-answer") -> None:
    async def fake_run_worker(**kwargs: Any):
        stream_context = kwargs.get("stream_context")
        run = worker_mod.WorkerRun(
            agent_code=kwargs["agent_code"],
            task=kwargs["task"],
            stream_content=kwargs["stream_content"],
        )
        run.output = WorkerOutput(
            agent_code=kwargs["agent_code"], task=kwargs["task"], answer=answer
        )

        async def events() -> AsyncIterator[str]:
            from urgs_deepagents_service.orchestrator.utils import sse

            yield sse(
                "worker",
                {"type": "worker", "status": "started", "agent_code": kwargs["agent_code"]},
                stream_context,
            )
            if kwargs["stream_content"]:
                yield sse("content", {"content": answer}, stream_context)
            yield sse(
                "worker",
                {"type": "worker", "status": "completed", "agent_code": kwargs["agent_code"]},
                stream_context,
            )

        run._events_factory = events
        return run

    monkeypatch.setattr(worker_mod, "run_worker", fake_run_worker)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_worker", fake_run_worker
    )


def _patch_finalizer(monkeypatch, answer: str = "final-answer") -> None:
    async def fake_finalize(**kwargs: Any) -> AsyncIterator[str]:
        from urgs_deepagents_service.orchestrator.utils import sse

        stream_context = kwargs.get("stream_context")
        yield sse("agent", {"type": "thinking", "title": "Finalizer 汇总"}, stream_context)
        yield sse("content", {"content": answer}, stream_context)

    monkeypatch.setattr(finalizer_mod, "stream_finalizer", fake_finalize)


@pytest.mark.asyncio
async def test_input_guard_rejected_emits_quality_risk(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=False, reason="敏感信息")
    request = OrchestratorRequest(messages="敏感内容", agents=_agents())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "input_guard" in names
    assert any(name == "quality_risk" for name in names)
    assert names[-1] == "done"
    guard_event = next(data for name, data in events if name == "input_guard")
    assert guard_event["status"] == "rejected"


@pytest.mark.asyncio
async def test_simple_path_passes_through_worker_answer(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="hello")
    _patch_review(monkeypatch, passed=True)

    # 简单单 Worker 已验收通过时，Finalizer 阶段直接发布完整答案，不再调用 LLM 汇总。
    async def fail_finalize(**kwargs: Any) -> AsyncIterator[str]:
        raise AssertionError("finalizer LLM should be skipped for simple single-worker pass")
        yield  # unreachable, make it an async generator

    monkeypatch.setattr(finalizer_mod, "stream_finalizer", fail_finalize)
    request = OrchestratorRequest(
        messages="请检查当前项目文件并回答问题",
        agents=_agents(),
        agent_configs=_configs(),
    )
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "routing" in names
    assert "content" in names
    assert names[-1] == "done"
    assert "quality_risk" not in names
    # 简单路径验收通过：Finalizer 阶段直接发布 Worker 的完整答案。
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "hello"
    content_event = next(data for name, data in events if name == "content")
    assert content_event["step_id"] == "finalizer.content"


@pytest.mark.asyncio
async def test_general_direct_answer_skips_planner_review_and_finalizer(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=True)
    captured: dict[str, Any] = {}

    async def fake_run_worker(**kwargs: Any):
        captured.update(kwargs)
        run = worker_mod.WorkerRun(
            agent_code=kwargs["agent_code"],
            task=kwargs["task"],
            stream_content=kwargs["stream_content"],
        )

        async def events() -> AsyncIterator[str]:
            from urgs_deepagents_service.orchestrator.utils import sse

            yield sse(
                "content",
                {"content": "React 深色模式示例"},
                kwargs["stream_context"],
                step_id="worker.general-agent.content",
                status="streaming",
                message="直接答案",
            )

        run._events_factory = events
        return run

    async def fail_stage(*args: Any, **kwargs: Any):
        raise AssertionError("直接解答不应进入 Planner 或 Reviewer")

    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_worker",
        fake_run_worker,
    )
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_planner",
        fail_stage,
    )
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_review",
        fail_stage,
    )
    request = OrchestratorRequest(
        messages="使用 React 实现一个深色模式切换功能。",
        agents=_agents(),
        agent_configs=_configs(),
        selected_agent_code="general-agent",
    )

    events = await _make_stream(monkeypatch, request)
    names = [name for name, _ in events]

    assert captured["direct_answer"] is True
    assert captured["stream_content"] is True
    assert "planning" not in names
    assert "review" not in names
    assert "finalizing" not in names
    assert names[-1] == "done"
    routing = next(data for name, data in events if name == "routing")
    assert routing["is_complex"] is False
    assert "直接解答" in routing["reason"]


@pytest.mark.asyncio
async def test_orchestrator_sse_envelope_and_simple_order(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="hello")
    _patch_review(monkeypatch, passed=True)
    request = OrchestratorRequest(
        messages="请检查当前项目文件并回答问题",
        agents=_agents(),
        agent_configs=_configs(),
    )
    events = await _make_stream(monkeypatch, request)

    _assert_envelope(events)
    names = [name for name, _ in events]
    _assert_subsequence(
        names,
        [
            "agent",
            "input_guard",
            "agent",
            "routing",
            "worker",
            "review",
            "finalizing",
            "content",
            "done",
        ],
    )
    done = events[-1][1]
    assert done["done"] is True
    assert done["quality_risk"] is False
    assert done["handoff"] is False
    assert done["rework_attempts"] == 0
    assert done["audit_event_count"] > 0


@pytest.mark.asyncio
async def test_local_input_guard_rejects_empty_without_model_config(monkeypatch) -> None:
    def fail_build_model(*args: Any, **kwargs: Any) -> object:
        raise AssertionError("empty input should be rejected before model config")

    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.build_chat_model",
        fail_build_model,
    )
    request = OrchestratorRequest(messages="   ", agents=_agents())
    events = await _collect(stream_orchestration(request, _FakeSettings()))

    _assert_envelope(events)
    guard = next(data for name, data in events if name == "input_guard")
    done = events[-1][1]
    assert guard["status"] == "rejected"
    assert guard["category"] == "empty"
    assert done["quality_risk"] is True


@pytest.mark.asyncio
async def test_model_config_failure_emits_sanitized_error(monkeypatch) -> None:
    def fail_build_model(*args: Any, **kwargs: Any) -> object:
        raise RuntimeError(
            "token=secret-token sk-secret123 http://127.0.0.1:8080/api/internal/config"
        )

    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.build_chat_model",
        fail_build_model,
    )
    request = OrchestratorRequest(messages="普通问题", agents=_agents())
    events = await _collect(stream_orchestration(request, _FakeSettings()))

    _assert_envelope(events)
    assert [name for name, _ in events] == ["agent", "error"]
    error = events[-1][1]
    error_text = json.dumps(error, ensure_ascii=False)
    assert "secret-token" not in error_text
    assert "sk-secret123" not in error_text
    assert "127.0.0.1" not in error_text
    assert "[REDACTED]" in error_text
    assert "[INTERNAL_URL]" in error_text


@pytest.mark.asyncio
async def test_skill_configuration_failure_emits_actionable_error(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)

    async def fail_worker(**kwargs: Any) -> worker_mod.WorkerRun:
        from urgs_deepagents_service.skill_loader import SkillConfigurationError

        raise SkillConfigurationError("监管查询 Skill 尚未启用或映射未完成")

    monkeypatch.setattr(worker_mod, "run_worker", fail_worker)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_worker", fail_worker)
    request = OrchestratorRequest(
        messages="查询贷款指标", agents=_agents(), agent_configs=_configs()
    )
    events = await _make_stream(monkeypatch, request)

    error = events[-1][1]
    assert error["error"] == "监管查询 Skill 配置不完整，请完成 Skill 映射后再启用 Agent"
    assert error["detail"] == "监管查询 Skill 尚未启用或映射未完成"


@pytest.mark.asyncio
async def test_complex_path_uses_planner_and_finalizer(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "lineage-agent", is_complex=True)
    _patch_planner(
        monkeypatch,
        [("metadata-agent" if False else "general-agent", "调研"), ("lineage-agent", "分析")],
    )
    _patch_worker(monkeypatch, answer="step-output")
    _patch_review(monkeypatch, passed=True)
    _patch_finalizer(monkeypatch, answer="final")
    request = OrchestratorRequest(messages="复杂任务", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "planning" in names
    # 复杂路径 worker 不直接产出 content，由 finalizer 产出
    planning = next(
        data for name, data in events if name == "planning" and data.get("status") == "completed"
    )
    assert len(planning["steps"]) == 2
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "final"
    assert "quality_risk" not in names


@pytest.mark.asyncio
async def test_finalizer_uses_control_agent_without_runtime_tools(monkeypatch) -> None:
    captured_kwargs: dict[str, Any] = {}

    class FakeFinalizer:
        async def astream_events(
            self,
            payload: dict[str, object],
            config: dict[str, object] | None = None,
            version: str = "v2",
        ) -> AsyncIterator[dict[str, object]]:
            assert "Worker 产出" in str(payload["messages"])
            assert config is not None
            assert version == "v2"
            yield {
                "event": "on_chat_model_stream",
                "name": "model",
                "data": {"chunk": SimpleNamespace(content="final")},
            }

    def fake_create_control_agent(**kwargs: Any) -> FakeFinalizer:
        captured_kwargs.update(kwargs)
        return FakeFinalizer()

    monkeypatch.setattr(finalizer_mod, "create_control_agent", fake_create_control_agent)

    events = await _collect(
        finalizer_mod.stream_finalizer(
            model=object(),
            settings=_FakeSettings(),
            agent_config=AgentRuntimeConfig(
                system_prompt="worker prompt",
                tool_allowlist=["read_file", "write_file"],
                allow_write=True,
            ),
            user_message="原始问题",
            outputs=[WorkerOutput(agent_code="general-agent", task="任务", answer="worker")],
            review=ReviewResult(passed=True, score=1.0),
            quality_risk=False,
            debug=False,
        )
    )

    assert captured_kwargs["debug"] is False
    assert captured_kwargs["model"] is not None
    assert "tool_allowlist" not in captured_kwargs
    assert "allow_write" not in captured_kwargs
    assert [name for name, _ in events] == ["agent", "content"]
    assert events[-1][1]["content"] == "final"


@pytest.mark.asyncio
async def test_complex_planner_only_receives_deepagents_candidates(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "lineage-agent", is_complex=True)
    captured_candidates: list[str] = []

    async def fake_planner(
        model: Any, user_message: str, candidate_agents: list[str]
    ) -> list[PlanStep]:
        captured_candidates.extend(candidate_agents)
        return [PlanStep(step=1, agent="lineage-agent", task="分析", depends_on=[])]

    monkeypatch.setattr(planner_mod, "run_planner", fake_planner)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_planner", fake_planner
    )
    _patch_worker(monkeypatch, answer="step-output")
    _patch_review(monkeypatch, passed=True)
    _patch_finalizer(monkeypatch, answer="final")
    request = OrchestratorRequest(messages="复杂任务", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    assert captured_candidates == ["general-agent", "lineage-agent"]
    assert "rag-agent" not in captured_candidates
    assert events[-1][0] == "done"


@pytest.mark.asyncio
async def test_complex_plan_handoffs_non_deepagents_step(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "lineage-agent", is_complex=True)
    _patch_planner(monkeypatch, [("rag-agent", "知识库问答")])

    async def fail_worker(**kwargs: Any):
        raise AssertionError("non-DeepAgents planned step must not run a worker")

    monkeypatch.setattr(worker_mod, "run_worker", fail_worker)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_worker", fail_worker)
    request = OrchestratorRequest(messages="复杂任务", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    handoff = next(data for name, data in events if name == "handoff")
    done = events[-1][1]
    assert "worker" not in names
    assert handoff["agent_code"] == "rag-agent"
    assert handoff["reason"] == "planned_step_without_deepagents_config"
    assert done["handoff"] is True


@pytest.mark.asyncio
async def test_rework_pass_finalizes_without_quality_risk(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="reworked")
    # 首次验收失败，返工后通过
    call_count = {"review": 0}

    async def fake_review(
        model: Any, user_message: str, outputs: list[WorkerOutput]
    ) -> ReviewResult:
        call_count["review"] += 1
        return ReviewResult(passed=False, score=0.3, reason="不完整", issues=["缺结论"])

    async def fake_review_fb(
        model: Any, user_message: str, outputs: list[WorkerOutput], feedback: str
    ) -> ReviewResult:
        return ReviewResult(passed=True, score=0.9, reason="返工通过")

    monkeypatch.setattr(reviewer_mod, "run_review", fake_review)
    monkeypatch.setattr(reviewer_mod, "run_review_with_feedback", fake_review_fb)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_review", fake_review)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_review_with_feedback", fake_review_fb
    )
    _patch_finalizer(monkeypatch, answer="final")
    request = OrchestratorRequest(
        messages="请检查当前项目文件并回答问题",
        agents=_agents(),
        agent_configs=_configs(),
    )
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "rework" in names
    assert "quality_risk" not in names
    assert "finalizing" in names
    # 返工通过后单 Worker：Finalizer 阶段直接发布 reworked 完整答案。
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "reworked"
    assert call_count["review"] == 1


@pytest.mark.asyncio
async def test_rework_context_includes_required_fixes_and_previous_output(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    contexts: list[str] = []
    captured_feedback: dict[str, str] = {}

    async def fake_run_worker(**kwargs: Any):
        stream_context = kwargs.get("stream_context")
        contexts.append(kwargs["context"])
        answer = "只有过程，没有结论" if len(contexts) == 1 else "补充后的明确结论"
        run = worker_mod.WorkerRun(
            agent_code=kwargs["agent_code"],
            task=kwargs["task"],
            stream_content=kwargs["stream_content"],
        )
        run.output = WorkerOutput(
            agent_code=kwargs["agent_code"], task=kwargs["task"], answer=answer
        )

        async def events() -> AsyncIterator[str]:
            from urgs_deepagents_service.orchestrator.utils import sse

            yield sse("worker", {"type": "worker", "status": "completed"}, stream_context)

        run._events_factory = events
        return run

    async def fake_review(
        model: Any, user_message: str, outputs: list[WorkerOutput]
    ) -> ReviewResult:
        return ReviewResult(
            passed=False,
            score=0.35,
            reason="缺少明确结论",
            issues=["没有回答用户最终要什么"],
            required_fixes=["补充明确结论", "给出可执行下一步"],
        )

    async def fake_review_fb(
        model: Any, user_message: str, outputs: list[WorkerOutput], feedback: str
    ) -> ReviewResult:
        captured_feedback["value"] = feedback
        return ReviewResult(passed=True, score=0.9, reason="返工通过")

    monkeypatch.setattr(worker_mod, "run_worker", fake_run_worker)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_worker", fake_run_worker
    )
    monkeypatch.setattr(reviewer_mod, "run_review", fake_review)
    monkeypatch.setattr(reviewer_mod, "run_review_with_feedback", fake_review_fb)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_review", fake_review)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_review_with_feedback", fake_review_fb
    )
    request = OrchestratorRequest(
        messages="请检查当前项目文件并回答问题",
        agents=_agents(),
        agent_configs=_configs(),
    )
    events = await _make_stream(monkeypatch, request)

    assert contexts[0] == ""
    assert "补充明确结论" in contexts[1]
    assert "给出可执行下一步" in contexts[1]
    assert "只有过程，没有结论" in contexts[1]
    assert "不要机械复述" in contexts[1]
    assert "补充明确结论" in captured_feedback["value"]
    rework = next(data for name, data in events if name == "rework")
    assert rework["required_fixes"] == ["补充明确结论", "给出可执行下一步"]


@pytest.mark.asyncio
async def test_rework_fail_emits_quality_risk(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="bad")
    # 两次验收均失败
    _patch_review(monkeypatch, passed=False, reason="仍不合格")

    async def fail_finalize(**kwargs: Any) -> AsyncIterator[str]:
        raise AssertionError("simple quality-risk result should not be rewritten by finalizer LLM")
        yield  # unreachable, make it an async generator

    monkeypatch.setattr(finalizer_mod, "stream_finalizer", fail_finalize)
    request = OrchestratorRequest(
        messages="请检查当前项目文件并回答问题",
        agents=_agents(),
        agent_configs=_configs(),
    )
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "rework" in names
    assert "quality_risk" in names
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "bad"
    assert names[-1] == "done"


@pytest.mark.asyncio
async def test_reviewer_parse_failure_fails_closed(monkeypatch) -> None:
    class FakeReviewer:
        async def ainvoke(self, payload: dict[str, object]) -> dict[str, object]:
            return {"messages": [{"role": "assistant", "content": "不是 JSON"}]}

    monkeypatch.setattr(reviewer_mod, "create_control_agent", lambda **kwargs: FakeReviewer())

    review = await reviewer_mod.run_review(
        object(),
        "用户问题",
        [WorkerOutput(agent_code="general-agent", task="回答", answer="候选答案")],
    )

    assert review.passed is False
    assert review.score == 0.0
    assert "解析失败" in review.reason
    assert review.required_fixes


@pytest.mark.asyncio
async def test_reviewer_rejects_answer_that_stopped_before_evidence_closed(monkeypatch) -> None:
    def fail_create_reviewer(**kwargs: Any) -> object:
        raise AssertionError("local evidence-closure check must fail before model review")

    monkeypatch.setattr(reviewer_mod, "create_control_agent", fail_create_reviewer)

    review = await reviewer_mod.run_review(
        object(),
        "福费廷业务在金融基础数据系统中如何报送？",
        [
            WorkerOutput(
                agent_code="regulatory-knowledge-agent",
                task="查询报送口径",
                answer=(
                    "由于工具调用限制，未能继续读取实体页和原文页的详细字段级内容。"
                    "根据目录推断报送到单位贷款表。"
                ),
            )
        ],
    )

    assert review.passed is False
    assert "证据闭合" in review.reason
    assert any("实体页或原文页" in item for item in review.required_fixes)


def test_reviewer_budget_guard_does_not_match_other_agents_or_incidental_wording() -> None:
    outputs = [
        WorkerOutput(
            agent_code="general-agent",
            task="说明边界",
            answer="由于工具调用限制，当前环境未能继续读取；这是预期的权限边界。",
        ),
        WorkerOutput(
            agent_code="regulatory-knowledge-agent",
            task="正常回答",
            answer="页面读取完成；没有出现未能继续读取的情况。",
        ),
    ]

    assert reviewer_mod._local_review_failure(outputs) is None


@pytest.mark.asyncio
async def test_handoff_for_non_deepagents(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "rag-agent", is_complex=False)
    request = OrchestratorRequest(messages="知识问答", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "routing" in names
    assert "handoff" in names
    handoff = next(data for name, data in events if name == "handoff")
    assert handoff["agent_code"] == "rag-agent"
    assert names[-1] == "done"


@pytest.mark.asyncio
async def test_selected_agent_code_keeps_agent_and_still_classifies_complexity(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_worker(monkeypatch, answer="direct")
    _patch_review(monkeypatch, passed=True)
    _patch_finalizer(monkeypatch, answer="final")
    seen: dict[str, Any] = {}

    async def fake_router(
        model: Any,
        user_message: str,
        agents: list[RouterAgentDescriptor],
        current_agent_code: str | None = None,
        conversation_context: str = "",
    ) -> RoutingResult:
        seen["agents"] = [agent.agent_code for agent in agents]
        return RoutingResult(
            agent_code="general-agent",
            confidence=0.7,
            reason="需要拆解",
            task_type="analysis",
            is_complex=True,
        )

    async def fake_planner(
        model: Any, user_message: str, candidate_agents: list[str]
    ) -> list[PlanStep]:
        seen["candidates"] = candidate_agents
        return [PlanStep(step=1, agent="general-agent", task="分析", depends_on=[])]

    monkeypatch.setattr(router_mod, "run_router", fake_router)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_router", fake_router)
    monkeypatch.setattr(planner_mod, "run_planner", fake_planner)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_planner", fake_planner
    )
    request = OrchestratorRequest(
        messages="请分析当前项目文件并给出修改方案",
        agents=_agents(),
        agent_configs=_configs(),
        selected_agent_code="general-agent",
    )
    events = await _make_stream(monkeypatch, request)

    routing = next(data for name, data in events if name == "routing")
    assert routing["agent_code"] == "general-agent"
    assert routing["is_complex"] is True
    assert seen["agents"] == ["general-agent"]
    assert seen["candidates"] == ["general-agent"]


def test_regulatory_impact_task_requires_coverage_review() -> None:
    assert requires_regulatory_coverage_review(
        "regulatory-knowledge-agent",
        "请分析同业存放业务变更影响哪些监管系统、报表和监管指标，并说明排除依据",
    )
    assert not requires_regulatory_coverage_review(
        "regulatory-knowledge-agent", "G01 的报送频度是什么"
    )
    assert not requires_regulatory_coverage_review(
        "general-agent", "请分析业务变更影响哪些监管报表"
    )


@pytest.mark.asyncio
async def test_regulatory_impact_runs_coverage_worker(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_review(monkeypatch, passed=True)
    _patch_finalizer(monkeypatch, answer="final")
    tasks: list[str] = []
    contexts: list[str] = []

    async def fake_router(
        model: Any,
        user_message: str,
        agents: list[RouterAgentDescriptor],
        current_agent_code: str | None = None,
        conversation_context: str = "",
    ) -> RoutingResult:
        return RoutingResult(
            agent_code="regulatory-knowledge-agent",
            confidence=0.8,
            reason="监管知识任务",
            task_type="regulatory-impact",
            is_complex=False,
        )

    async def fake_planner(
        model: Any, user_message: str, candidate_agents: list[str]
    ) -> list[PlanStep]:
        assert candidate_agents == ["regulatory-knowledge-agent"]
        return [
            PlanStep(
                step=1,
                agent="regulatory-knowledge-agent",
                task="完成主分析",
                depends_on=[],
            )
        ]

    async def fake_run_worker(**kwargs: Any):
        tasks.append(kwargs["task"])
        contexts.append(kwargs["context"])
        run = worker_mod.WorkerRun(
            agent_code=kwargs["agent_code"],
            task=kwargs["task"],
            stream_content=False,
        )
        run.output = WorkerOutput(
            agent_code=kwargs["agent_code"],
            task=kwargs["task"],
            answer="主分析结果" if len(tasks) == 1 else "覆盖复核结果",
        )

        async def events() -> AsyncIterator[str]:
            from urgs_deepagents_service.orchestrator.utils import sse

            yield sse("worker", {"type": "worker", "status": "completed"})

        run._events_factory = events
        return run

    monkeypatch.setattr(router_mod, "run_router", fake_router)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_router", fake_router)
    monkeypatch.setattr(planner_mod, "run_planner", fake_planner)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_planner", fake_planner
    )
    monkeypatch.setattr(worker_mod, "run_worker", fake_run_worker)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_worker", fake_run_worker
    )
    agents = [
        RouterAgentDescriptor(
            agent_code="regulatory-knowledge-agent",
            agent_name="监管助手",
            agent_type="SPECIALIST",
            build_mode="DEEPAGENTS",
            description="监管知识问答",
        )
    ]
    configs = {
        "regulatory-knowledge-agent": AgentRuntimeConfig(system_prompt="监管知识助手")
    }
    request = OrchestratorRequest(
        messages="分析同业存放业务变更影响哪些监管系统、报表和监管指标，并说明排除依据",
        agents=agents,
        agent_configs=configs,
        selected_agent_code="regulatory-knowledge-agent",
    )

    events = await _make_stream(monkeypatch, request)

    routing = next(data for name, data in events if name == "routing")
    assert routing["is_complex"] is True
    assert len(tasks) == 2
    assert tasks[0] == "完成主分析"
    assert "执行监管影响覆盖复核" in tasks[1]
    assert "主分析结果" in contexts[1]


@pytest.mark.asyncio
async def test_current_agent_code_is_soft_binding_and_still_routes(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_worker(monkeypatch, answer="direct")
    _patch_review(monkeypatch, passed=True)
    seen: dict[str, Any] = {}

    async def fake_router(
        model: Any,
        user_message: str,
        agents: Any,
        current_agent_code: str | None = None,
        conversation_context: str = "",
    ) -> RoutingResult:
        seen["current_agent_code"] = current_agent_code
        seen["conversation_context"] = conversation_context
        return RoutingResult(
            agent_code="lineage-agent",
            confidence=0.88,
            reason="切换到更匹配的血缘助手",
            task_type="lineage",
            is_complex=False,
        )

    monkeypatch.setattr(router_mod, "run_router", fake_router)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_router", fake_router)
    request = OrchestratorRequest(
        messages=[
            {"role": "user", "content": "刚才的问题继续"},
            {"role": "assistant", "content": "已使用通用助手回答"},
            {"role": "user", "content": "分析这段 SQL 血缘"},
        ],
        agents=_agents(),
        agent_configs=_configs(),
        current_agent_code="general-agent",
    )
    events = await _make_stream(monkeypatch, request)

    routing = next(data for name, data in events if name == "routing")
    assert seen["current_agent_code"] == "general-agent"
    assert "已使用通用助手回答" in seen["conversation_context"]
    assert routing["agent_code"] == "lineage-agent"
    assert routing["current_agent_code"] == "general-agent"
    assert routing["reused_current_agent"] is False


@pytest.mark.asyncio
async def test_data_query_catalog_followup_reuses_current_agent_without_model(
    monkeypatch,
) -> None:
    def fail_create_control_agent(**kwargs: Any) -> Any:
        pytest.fail("数据目录续问应确定性复用当前 Agent，不应再次调用 Router 模型")

    monkeypatch.setattr(router_mod, "create_control_agent", fail_create_control_agent)
    agents = [
        RouterAgentDescriptor(
            agent_code="regulatory-data-query-agent",
            agent_name="监管指标数据查询助手",
            agent_type="SPECIALIST",
            build_mode="DEEPAGENTS",
            description="查询实际监管指标数据和已接入目录",
        ),
        RouterAgentDescriptor(
            agent_code="regulatory-knowledge-agent",
            agent_name="监管助手",
            agent_type="SPECIALIST",
            build_mode="DEEPAGENTS",
            description="解释监管制度、报表和指标口径",
        ),
    ]

    result = await router_mod.run_router(
        model=object(),
        user_message="都能查哪些指标",
        agents=agents,
        current_agent_code="regulatory-data-query-agent",
        conversation_context=(
            "用户：帮我分析今年各项存款走势\n"
            "助手：当前数据查询目录未配置各项存款指标"
        ),
    )

    assert result.agent_code == "regulatory-data-query-agent"
    assert result.reused_current_agent is True
    assert result.task_type == "监管数据查询能力续问"


def test_data_query_followup_requires_context_and_allows_knowledge_switch() -> None:
    agents = [
        RouterAgentDescriptor(
            agent_code="regulatory-data-query-agent",
            agent_name="监管指标数据查询助手",
        )
    ]

    without_context = router_mod._regulatory_data_query_continuation(
        "都能查哪些指标",
        "regulatory-data-query-agent",
        "",
        agents,
    )
    knowledge_request = router_mod._regulatory_data_query_continuation(
        "各项存款的监管口径和报送要求是什么",
        "regulatory-data-query-agent",
        "助手：当前数据查询目录未配置各项存款指标",
        agents,
    )

    assert without_context is None
    assert knowledge_request is None


def test_build_agent_kwargs_writable_requires_write_tools(tmp_path) -> None:
    from urgs_deepagents_service.orchestrator.utils import (
        READ_ONLY_FILESYSTEM_PERMISSIONS,
        build_agent_kwargs,
    )

    class S:
        memory_files = ""
        skill_dirs = ""
        workspace_root = None
        enable_write_tools = False

    # allow_write=True 但白名单不含 write_file/edit_file：仍只读（避免无效放开）
    kwargs = build_agent_kwargs(
        settings=S(),
        memory_files=None,
        skill_dirs=None,
        tool_allowlist=["ls", "read_file"],
        allow_write=True,
        workspace_root=str(tmp_path),
        debug=False,
    )
    assert kwargs["permissions"] == READ_ONLY_FILESYSTEM_PERMISSIONS

    # 即使白名单含 write_file，服务端未启用写工具时仍只读
    kwargs = build_agent_kwargs(
        settings=S(),
        memory_files=None,
        skill_dirs=None,
        tool_allowlist=["ls", "read_file", "write_file", "edit_file"],
        allow_write=True,
        workspace_root=str(tmp_path),
        debug=False,
    )
    assert kwargs["permissions"] == READ_ONLY_FILESYSTEM_PERMISSIONS

    class WriteEnabledSettings(S):
        enable_write_tools = True

    # 白名单含 write_file 且服务端启用写工具：放开写权限，且 backend 使用 agent 级根
    kwargs = build_agent_kwargs(
        settings=WriteEnabledSettings(),
        memory_files=None,
        skill_dirs=None,
        tool_allowlist=["ls", "read_file", "write_file", "edit_file"],
        allow_write=True,
        workspace_root=str(tmp_path),
        debug=False,
    )
    assert kwargs["permissions"] == []
    assert "backend" in kwargs


def test_build_agent_kwargs_workspace_root_overrides_settings(tmp_path) -> None:
    from urgs_deepagents_service.orchestrator.utils import build_agent_kwargs

    class S:
        memory_files = ""
        skill_dirs = ""
        workspace_root = "/global/workspace"

    agent_root = str(tmp_path)
    kwargs = build_agent_kwargs(
        settings=S(),
        memory_files=["/AGENTS.md"],
        skill_dirs=None,
        tool_allowlist=None,
        allow_write=False,
        workspace_root=agent_root,
        debug=False,
    )
    # agent 级 workspace_root 覆盖全局：backend 已创建且 memory 已加载
    assert "backend" in kwargs
    assert kwargs["memory"] == ["/AGENTS.md"]
