from fastapi import APIRouter
from sse_starlette.sse import EventSourceResponse

from agent.graph import AgentOrchestrator
from schemas.api import ChatRequest, ChatResponse

router = APIRouter()

agent = AgentOrchestrator()


@router.post("/chat", response_model=ChatResponse)
async def chat_endpoint(payload: ChatRequest) -> ChatResponse:
    return await agent.run_chat(payload)


@router.post("/chat/stream")
async def chat_stream(payload: ChatRequest) -> EventSourceResponse:
    async def event_generator():
        async for event in agent.run_chat_stream(payload):
            yield event.as_sse_message()

    return EventSourceResponse(event_generator())
