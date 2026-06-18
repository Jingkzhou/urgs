"""URGS 多 Agent 编排模块。

按 AGENTS.md 职责边界，Input Guard / Router / Planner / Worker / Reviewer /
Finalizer / 返工 / quality_risk 等编排逻辑全部落在此包内。`urgs-api` 仅作为
适配器调用 `stream_orchestration` 并转发 SSE、持久化事件。
"""

from urgs_deepagents_service.orchestrator.orchestrator import stream_orchestration
from urgs_deepagents_service.orchestrator.state import (
    GuardResult,
    PlanStep,
    ReviewResult,
    RoutingResult,
    WorkerOutput,
)

__all__ = [
    "GuardResult",
    "PlanStep",
    "ReviewResult",
    "RoutingResult",
    "WorkerOutput",
    "stream_orchestration",
]
