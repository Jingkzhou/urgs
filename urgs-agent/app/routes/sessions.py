from fastapi import APIRouter

from agent.graph import AgentOrchestrator
from schemas.api import SessionEventsResponse, SessionSummary

router = APIRouter()

agent = AgentOrchestrator()


@router.get("/{session_id}", response_model=SessionSummary)
async def get_session(session_id: str) -> SessionSummary:
    return await agent.get_session_summary(session_id)


@router.get("/{session_id}/events", response_model=SessionEventsResponse)
async def get_session_events(session_id: str) -> SessionEventsResponse:
    return await agent.get_session_events(session_id)
