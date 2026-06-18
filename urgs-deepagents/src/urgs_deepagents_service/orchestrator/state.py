"""编排各阶段的结构化结果模型。"""

from __future__ import annotations

from pydantic import BaseModel, Field


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


class WorkerOutput(BaseModel):
    """单个 Worker 执行产出。"""

    agent_code: str
    task: str
    answer: str
    step: int | None = None
