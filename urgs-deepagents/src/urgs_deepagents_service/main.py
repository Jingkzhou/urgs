from collections.abc import AsyncIterator
from contextlib import asynccontextmanager
from typing import Any

from deepagents import __version__, create_deep_agent
from fastapi import FastAPI

from urgs_deepagents_service.config import get_settings
from urgs_deepagents_service.model_config import build_chat_model
from urgs_deepagents_service.schemas import InvokeRequest, InvokeResponse, UpstreamInfo

UPSTREAM_REPOSITORY = "https://github.com/langchain-ai/deepagents"
UPSTREAM_COMMIT = "4ffea88690418207b5e4fa800ee8c1abfa454bec"


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    app.state.settings = get_settings()
    yield


def _serialize(value: Any) -> Any:
    if hasattr(value, "model_dump"):
        return value.model_dump(mode="json")
    if isinstance(value, dict):
        return {key: _serialize(item) for key, item in value.items()}
    if isinstance(value, list):
        return [_serialize(item) for item in value]
    return value


def create_app() -> FastAPI:
    settings = get_settings()
    app = FastAPI(title="URGS DeepAgents Service", version="0.1.0", lifespan=lifespan)

    @app.get("/health/live", tags=["health"])
    def live() -> dict[str, str]:
        return {"status": "UP", "service": settings.service_name}

    @app.get("/v1/upstream", response_model=UpstreamInfo, tags=["deepagents"])
    def upstream() -> UpstreamInfo:
        return UpstreamInfo(
            package="deepagents",
            version=__version__,
            repository=UPSTREAM_REPOSITORY,
            commit=UPSTREAM_COMMIT,
            license="MIT",
        )

    @app.post("/v1/agents/invoke", response_model=InvokeResponse, tags=["deepagents"])
    def invoke(request: InvokeRequest) -> InvokeResponse:
        model = build_chat_model(settings, request.model or settings.model)
        agent = create_deep_agent(
            model=model,
            tools=[],
            system_prompt=request.system_prompt,
            debug=request.debug,
        )
        result = agent.invoke({"messages": request.messages})
        return InvokeResponse(output=_serialize(result))

    return app


app = create_app()
