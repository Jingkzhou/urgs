from dataclasses import dataclass, field
from typing import Any, Dict, List, Optional

from schemas.api import PendingApproval


@dataclass
class AgentState:
    session_id: str
    messages: List[Dict[str, Any]] = field(default_factory=list)
    context: Dict[str, Any] = field(default_factory=dict)
    plan: List[Dict[str, Any]] = field(default_factory=list)
    tool_budget: Dict[str, int] = field(default_factory=lambda: {"max_calls": 8, "used": 0})
    pending_approval: Optional[PendingApproval] = None
    audit_trace_id: Optional[str] = None
    final_answer: Optional[str] = None

    def has_budget(self) -> bool:
        max_calls = self.tool_budget.get("max_calls", 0)
        used = self.tool_budget.get("used", 0)
        return used < max_calls

    def increment_tool_usage(self) -> None:
        self.tool_budget["used"] = self.tool_budget.get("used", 0) + 1
