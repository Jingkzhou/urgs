from fastapi import FastAPI

from app.middleware.auth import AuthMiddleware
from app.middleware.trace import TraceMiddleware
from app.routes import approvals, chat, health, sessions


def create_app() -> FastAPI:
    app = FastAPI(title="URGS Agent", version="0.1.0")
    app.add_middleware(TraceMiddleware)
    app.add_middleware(AuthMiddleware)
    app.include_router(chat.router)
    app.include_router(sessions.router, prefix="/sessions")
    app.include_router(approvals.router, prefix="/approvals")
    app.include_router(health.router)
    return app


app = create_app()
