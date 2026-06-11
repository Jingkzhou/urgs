import asyncio
import json
import uuid
from typing import Annotated, Any

from fastapi import APIRouter, Depends, Header, HTTPException, Query, Response, status
from sqlalchemy import text
from sse_starlette.sse import EventSourceResponse

from urgs_agent.api.dependencies import get_container, require_api_key
from urgs_agent.container import Container
from urgs_agent.domain.enums import TERMINAL_RUN_STATUSES, RunStatus
from urgs_agent.domain.schemas import (
    AgentCreate,
    AgentRead,
    AgentVersionCreate,
    AgentVersionRead,
    EventRead,
    ResumeRunRequest,
    RunCreate,
    RunRead,
)
from urgs_agent.storage.repositories import ConflictError, NotFoundError

router = APIRouter(dependencies=[Depends(require_api_key)])
health = APIRouter()


def _translate_error(exc: Exception) -> HTTPException:
    if isinstance(exc, NotFoundError):
        return HTTPException(status_code=404, detail=str(exc))
    if isinstance(exc, ConflictError):
        return HTTPException(status_code=409, detail=str(exc))
    return HTTPException(status_code=400, detail=str(exc))


@router.post("/agents", response_model=AgentRead, status_code=status.HTTP_201_CREATED)
async def create_agent(
    data: AgentCreate, container: Annotated[Container, Depends(get_container)]
) -> Any:
    try:
        return await container.agents.create(data)
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.get("/agents/{agent_id}", response_model=AgentRead)
async def get_agent(agent_id: str, container: Annotated[Container, Depends(get_container)]) -> Any:
    try:
        return await container.agents.get(agent_id)
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.post(
    "/agents/{agent_id}/versions",
    response_model=AgentVersionRead,
    status_code=status.HTTP_201_CREATED,
)
async def create_agent_version(
    agent_id: str,
    data: AgentVersionCreate,
    container: Annotated[Container, Depends(get_container)],
) -> Any:
    try:
        container.compiler.validate(data.definition)
        return await container.agents.create_version(agent_id, data.definition)
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.post("/agents/{agent_id}/versions/{version}/publish", response_model=AgentVersionRead)
async def publish_agent_version(
    agent_id: str,
    version: int,
    container: Annotated[Container, Depends(get_container)],
) -> Any:
    try:
        candidate = await container.agents.resolve_version(agent_id, version)
        container.compiler.validate(AgentVersionRead.model_validate(candidate).definition)
        return await container.agents.publish(agent_id, version)
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.post("/runs", response_model=RunRead, status_code=status.HTTP_202_ACCEPTED)
async def create_run(
    data: RunCreate,
    response: Response,
    container: Annotated[Container, Depends(get_container)],
) -> Any:
    try:
        version = await container.agents.resolve_version(data.agent_id, data.agent_version)
        if data.callback_url and not container.settings.callback_hmac_secret:
            raise ValueError("callback URL requires AGENT_CALLBACK_HMAC_SECRET")
        run, created = await container.runs.create(data, version.version)
        if created:
            await container.broker.enqueue(run.run_id)
        else:
            response.status_code = status.HTTP_200_OK
        if data.wait_seconds:
            deadline = asyncio.get_running_loop().time() + data.wait_seconds
            while asyncio.get_running_loop().time() < deadline:
                run = await container.runs.get(run.run_id)
                if run.status in TERMINAL_RUN_STATUSES or run.status == RunStatus.WAITING_APPROVAL:
                    response.status_code = status.HTTP_200_OK
                    break
                await asyncio.sleep(0.2)
        return run
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.get("/runs/{run_id}", response_model=RunRead)
async def get_run(
    run_id: uuid.UUID, container: Annotated[Container, Depends(get_container)]
) -> Any:
    try:
        return await container.runs.get(run_id)
    except Exception as exc:
        raise _translate_error(exc) from exc


def _event_dict(event: Any) -> dict[str, Any]:
    return EventRead.model_validate(event).model_dump(mode="json")


@router.get("/runs/{run_id}/events")
async def stream_events(
    run_id: uuid.UUID,
    container: Annotated[Container, Depends(get_container)],
    last_event_id: Annotated[str | None, Header(alias="Last-Event-ID")] = None,
    after: int = Query(default=0, ge=0),
) -> EventSourceResponse:
    try:
        await container.runs.get(run_id)
    except Exception as exc:
        raise _translate_error(exc) from exc
    cursor = after
    if last_event_id and last_event_id.isdigit():
        cursor = max(cursor, int(last_event_id))

    async def generate() -> Any:
        nonlocal cursor
        history = await container.events.list(run_id, cursor)
        for event in history:
            cursor = event.sequence
            yield {
                "id": str(event.sequence),
                "event": event.event_type,
                "data": json.dumps(_event_dict(event), ensure_ascii=False),
            }
        run = await container.runs.get(run_id)
        if run.status in TERMINAL_RUN_STATUSES:
            return
        async for published in container.broker.subscribe(run_id):
            if not published:
                run = await container.runs.get(run_id)
                if run.status in TERMINAL_RUN_STATUSES:
                    return
                continue
            raw_sequence = published["sequence"]
            if not isinstance(raw_sequence, int):
                continue
            sequence = raw_sequence
            if sequence <= cursor:
                continue
            cursor = sequence
            yield {
                "id": str(sequence),
                "event": str(published["event_type"]),
                "data": json.dumps(published, ensure_ascii=False),
            }
            if published["event_type"] in {
                "run.completed",
                "run.failed",
                "run.cancelled",
            }:
                return

    return EventSourceResponse(
        generate(),
        ping=container.settings.sse_heartbeat_seconds,
        headers={"X-Accel-Buffering": "no"},
    )


@router.post("/runs/{run_id}/resume", response_model=RunRead, status_code=202)
async def resume_run(
    run_id: uuid.UUID,
    data: ResumeRunRequest,
    container: Annotated[Container, Depends(get_container)],
) -> Any:
    try:
        await container.runs.set_resume_value(run_id, data.value)
        await container.events.resolve_latest_approval(run_id, data.value)
        await container.broker.enqueue(run_id)
        return await container.runs.get(run_id)
    except Exception as exc:
        raise _translate_error(exc) from exc


@router.post("/runs/{run_id}/cancel", response_model=RunRead, status_code=202)
async def cancel_run(
    run_id: uuid.UUID, container: Annotated[Container, Depends(get_container)]
) -> Any:
    try:
        run = await container.runs.get(run_id)
        if run.status not in TERMINAL_RUN_STATUSES:
            await container.broker.request_cancel(run_id)
            if run.status in {RunStatus.QUEUED, RunStatus.WAITING_APPROVAL, RunStatus.PAUSED}:
                await container.runs.transition(run_id, RunStatus.CANCELLED)
        return await container.runs.get(run_id)
    except Exception as exc:
        raise _translate_error(exc) from exc


@health.get("/live")
async def live() -> dict[str, str]:
    return {"status": "ok"}


@health.get("/ready")
async def ready(container: Annotated[Container, Depends(get_container)]) -> dict[str, str]:
    try:
        async with container.sessions() as session:
            await session.execute(text("SELECT 1"))
        await container.redis.ping()
    except Exception as exc:
        raise HTTPException(status_code=503, detail=f"dependency unavailable: {exc}") from exc
    return {"status": "ready"}
