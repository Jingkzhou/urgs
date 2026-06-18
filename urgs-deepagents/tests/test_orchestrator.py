"""编排模块单测：通过 monkeypatch 替换模型调用与各阶段，验证编排流程与 SSE 事件。"""

from __future__ import annotations

import json
from collections.abc import AsyncIterator
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
from urgs_deepagents_service.orchestrator.state import (
    GuardResult,
    PlanStep,
    ReviewResult,
    RoutingResult,
    WorkerOutput,
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


def _patch_guard(monkeypatch, passed: bool, reason: str = "") -> None:
    async def fake_guard(model: Any, user_message: str) -> GuardResult:
        return GuardResult(passed=passed, reason=reason, category="" if passed else "injection")

    monkeypatch.setattr(guard_mod, "run_input_guard", fake_guard)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.run_input_guard", fake_guard
    )


def _patch_router(monkeypatch, agent_code: str, is_complex: bool) -> None:
    async def fake_router(model: Any, user_message: str, agents: Any) -> RoutingResult:
        return RoutingResult(
            agent_code=agent_code,
            confidence=0.9,
            reason="test",
            task_type="test",
            is_complex=is_complex,
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
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.stream_finalizer", fake_finalize
    )


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

    # Finalizer 不应被调用：若调用则抛错
    async def fail_finalize(**kwargs: Any) -> AsyncIterator[str]:
        raise AssertionError("finalizer should be skipped for simple single-worker pass")
        yield  # unreachable, make it an async generator

    monkeypatch.setattr(finalizer_mod, "stream_finalizer", fail_finalize)
    monkeypatch.setattr(
        "urgs_deepagents_service.orchestrator.orchestrator.stream_finalizer", fail_finalize
    )
    request = OrchestratorRequest(messages="你好", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "routing" in names
    assert "content" in names
    assert names[-1] == "done"
    assert "quality_risk" not in names
    # 简单路径验收通过：直接透传 Worker 答案，不调 Finalizer
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "hello"


@pytest.mark.asyncio
async def test_orchestrator_sse_envelope_and_simple_order(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="hello")
    _patch_review(monkeypatch, passed=True)
    request = OrchestratorRequest(messages="你好", agents=_agents(), agent_configs=_configs())
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
    request = OrchestratorRequest(messages="问题", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "rework" in names
    assert "quality_risk" not in names
    assert "finalizing" in names
    # 返工通过后单 Worker：直接透传 reworked 答案，不调 Finalizer
    content = "".join(data["content"] for name, data in events if name == "content")
    assert content == "reworked"
    assert call_count["review"] == 1


@pytest.mark.asyncio
async def test_rework_fail_emits_quality_risk(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_router(monkeypatch, "general-agent", is_complex=False)
    _patch_worker(monkeypatch, answer="bad")
    # 两次验收均失败
    _patch_review(monkeypatch, passed=False, reason="仍不合格")
    _patch_finalizer(monkeypatch, answer="best-effort")
    request = OrchestratorRequest(messages="问题", agents=_agents(), agent_configs=_configs())
    events = await _make_stream(monkeypatch, request)

    names = [name for name, _ in events]
    assert "rework" in names
    assert "quality_risk" in names
    assert names[-1] == "done"


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
async def test_selected_agent_code_skips_router(monkeypatch) -> None:
    _patch_guard(monkeypatch, passed=True)
    _patch_worker(monkeypatch, answer="direct")
    _patch_review(monkeypatch, passed=True)

    # 若 router 被调用会抛错，确保未调用
    async def fail_router(*args: Any, **kwargs: Any) -> RoutingResult:
        raise AssertionError("router should be skipped when selected_agent_code set")

    monkeypatch.setattr(router_mod, "run_router", fail_router)
    monkeypatch.setattr("urgs_deepagents_service.orchestrator.orchestrator.run_router", fail_router)
    request = OrchestratorRequest(
        messages="问题",
        agents=_agents(),
        agent_configs=_configs(),
        selected_agent_code="general-agent",
    )
    events = await _make_stream(monkeypatch, request)

    routing = next(data for name, data in events if name == "routing")
    assert routing["agent_code"] == "general-agent"
    assert routing["task_type"] == "manual"


def test_build_agent_kwargs_writable_requires_write_tools(tmp_path) -> None:
    from urgs_deepagents_service.orchestrator.utils import (
        READ_ONLY_FILESYSTEM_PERMISSIONS,
        build_agent_kwargs,
    )

    class S:
        memory_files = ""
        skill_dirs = ""
        workspace_root = None

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

    # 白名单含 write_file 且 allow_write=True：放开写权限，且 backend 使用 agent 级根
    kwargs = build_agent_kwargs(
        settings=S(),
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
