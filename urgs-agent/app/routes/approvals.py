from fastapi import APIRouter
import uuid

from schemas.api import (
    ApprovalDecisionRequest,
    ApprovalDecisionResponse,
    ApprovalStatus,
)
from storage.audit_store import audit_store
from storage.session_store import session_store

router = APIRouter()


@router.post("/{approval_id}/confirm", response_model=ApprovalDecisionResponse)
async def confirm_approval(
    approval_id: str, payload: ApprovalDecisionRequest
) -> ApprovalDecisionResponse:
    # 1. 获取并移除待审批记录
    record = await session_store.pop_pending(approval_id)
    trace_id = uuid.uuid4().hex

    if not record:
        return ApprovalDecisionResponse(
            approval_id=approval_id, status=ApprovalStatus.REJECTED, next="RESUME_GRAPH"
        )

    session_id, approval = record

    # 2. 确定审批结果
    status = (
        ApprovalStatus.APPROVED
        if payload.decision.value == "APPROVE"
        else ApprovalStatus.REJECTED
    )

    # 3. 记录审计日志
    await audit_store.record_event(
        session_id,
        f"approval_{status.value.lower()}",
        {"comment": payload.comment or "", "approval_id": approval.approval_id},
        trace_id,
    )

    # 4. 更新会话状态
    await session_store.set_status(session_id, status.value)

    return ApprovalDecisionResponse(
        approval_id=approval_id, status=status, next="RESUME_GRAPH"
    )
