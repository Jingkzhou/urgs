from fastapi import APIRouter

from agent.graph import AgentOrchestrator
from schemas.api import ApprovalDecisionRequest, ApprovalDecisionResponse

router = APIRouter()

agent = AgentOrchestrator()


@router.post("/{approval_id}/confirm", response_model=ApprovalDecisionResponse)
async def confirm_approval(approval_id: str, payload: ApprovalDecisionRequest) -> ApprovalDecisionResponse:
    return await agent.handle_approval(approval_id, payload)
