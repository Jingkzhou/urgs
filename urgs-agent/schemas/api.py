from datetime import datetime
from enum import Enum
from typing import List, Optional

from pydantic import BaseModel, Field

from schemas.events import EventRecord


class RequestContext(BaseModel):
    env: Optional[str] = None
    project: Optional[str] = None
    locale: Optional[str] = None


class ChatRequest(BaseModel):
    session_id: Optional[str] = None
    user_id: str
    text: str
    context: Optional[RequestContext] = None


class PendingApproval(BaseModel):
    approval_id: str
    reason: str
    action_summary: str
    expires_at: Optional[datetime] = None


class ChatStatus(str, Enum):
    COMPLETED = "COMPLETED"
    NEED_APPROVAL = "NEED_APPROVAL"
    FAILED = "FAILED"


class ChatResponse(BaseModel):
    session_id: str
    message_id: str
    answer: Optional[str] = None
    status: ChatStatus = ChatStatus.COMPLETED
    pending_approval: Optional[PendingApproval] = None


class ApprovalDecision(str, Enum):
    APPROVE = "APPROVE"
    REJECT = "REJECT"


class ApprovalDecisionRequest(BaseModel):
    user_id: str
    decision: ApprovalDecision
    comment: Optional[str] = None


class ApprovalStatus(str, Enum):
    APPROVED = "APPROVED"
    REJECTED = "REJECTED"


class ApprovalDecisionResponse(BaseModel):
    approval_id: str
    status: ApprovalStatus
    next: str = "RESUME_GRAPH"


class SessionSummary(BaseModel):
    session_id: str
    status: str
    recent_messages: List[str] = Field(default_factory=list)


class SessionEventsResponse(BaseModel):
    session_id: str
    events: List[EventRecord] = Field(default_factory=list)


class HealthResponse(BaseModel):
    status: str
