"""编排各阶段的结构化结果模型。"""

from __future__ import annotations

from typing import Any, Literal

from pydantic import BaseModel, Field

StageName = Literal[
    "input_guard",
    "routing",
    "planning",
    "worker",
    "review",
    "rework",
    "finalizing",
    "quality_risk",
    "handoff",
    "done",
    "error",
]
StageStatus = Literal[
    "started",
    "completed",
    "passed",
    "failed",
    "rejected",
    "streaming",
    "skipped",
]
ExecutionPath = Literal["simple", "complex", "handoff"]


class GuardResult(BaseModel):
    """Input Guard 校验结果。"""

    passed: bool = Field(description="是否放行")
    reason: str = Field(default="", description="放行或拒绝原因")
    category: str = Field(
        default="", description="拒绝类别：injection/sensitive/empty/disallowed/other"
    )


class RoutingResult(BaseModel):
    """Router / Supervisor 路由与复杂度判断结果。"""

    agent_code: str
    confidence: float = Field(ge=0.0, le=1.0)
    reason: str = ""
    task_type: str = ""
    is_complex: bool = Field(default=False, description="是否为复杂任务，需要 Planner 拆解")
    collaboration_plan: str = ""


class PlanStep(BaseModel):
    """Planner 拆解出的子任务步骤。"""

    step: int
    agent: str = Field(description="负责该步骤的 agent_code")
    task: str = Field(description="该步骤的具体任务描述")
    depends_on: list[int] = Field(default_factory=list)


class ReviewResult(BaseModel):
    """Reviewer 验收结果。"""

    passed: bool
    score: float = Field(default=0.0, ge=0.0, le=1.0, description="质量评分")
    reason: str = ""
    issues: list[str] = Field(default_factory=list)
    required_fixes: list[str] = Field(default_factory=list, description="返工时必须修复的问题")


class WorkerOutput(BaseModel):
    """单个 Worker 执行产出。"""

    agent_code: str
    task: str
    answer: str
    step: int | None = None
    tool_results: list[dict[str, Any]] = Field(default_factory=list)


class StageRecord(BaseModel):
    """单个编排阶段的最小审计记录，后续可直接映射到落库事件。"""

    stage: StageName
    status: StageStatus
    message: str = ""
    agent_code: str | None = None
    details: dict[str, Any] = Field(default_factory=dict)


class OrchestrationState(BaseModel):
    """一次编排运行的结构化生命周期状态。"""

    run_id: str
    user_message: str = ""
    path: ExecutionPath | None = None
    selected_agent_code: str | None = None
    routing: RoutingResult | None = None
    plan: list[PlanStep] = Field(default_factory=list)
    worker_outputs: list[WorkerOutput] = Field(default_factory=list)
    reviews: list[ReviewResult] = Field(default_factory=list)
    rework_attempts: int = 0
    quality_risk: bool = False
    quality_risk_reason: str = ""
    handoff_agent_code: str | None = None
    audit_events: list[StageRecord] = Field(default_factory=list)

    def record(
        self,
        stage: StageName,
        status: StageStatus,
        message: str = "",
        *,
        agent_code: str | None = None,
        details: dict[str, Any] | None = None,
    ) -> StageRecord:
        event = StageRecord(
            stage=stage,
            status=status,
            message=message,
            agent_code=agent_code,
            details=details or {},
        )
        self.audit_events.append(event)
        return event

    def done_payload(self) -> dict[str, Any]:
        """Compact completion payload that keeps old `done=true` compatibility."""

        return {
            "done": True,
            "quality_risk": self.quality_risk,
            "quality_risk_reason": self.quality_risk_reason,
            "handoff": self.path == "handoff",
            "handoff_agent_code": self.handoff_agent_code,
            "rework_attempts": self.rework_attempts,
            "audit_event_count": len(self.audit_events),
        }
