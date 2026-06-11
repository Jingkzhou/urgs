from collections.abc import AsyncIterator
from contextlib import asynccontextmanager

from fastapi import FastAPI

from urgs_agent.api.routes import health, router
from urgs_agent.config import get_settings
from urgs_agent.container import Container
from urgs_agent.observability import configure_logging, configure_tracing


@asynccontextmanager
async def lifespan(app: FastAPI) -> AsyncIterator[None]:
    container = Container.build(get_settings())
    app.state.container = container
    try:
        yield
    finally:
        await container.close()


def create_app() -> FastAPI:
    settings = get_settings()
    configure_logging(settings)
    app = FastAPI(title="URGS Agent Runtime", version="0.1.0", lifespan=lifespan)
    app.include_router(health, prefix="/health", tags=["health"])
    app.include_router(router, prefix="/v1", tags=["runtime"])
    configure_tracing(app, settings)
    return app


app = create_app()
