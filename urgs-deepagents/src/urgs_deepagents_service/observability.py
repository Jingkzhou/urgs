"""Structured logging and request correlation helpers."""

from __future__ import annotations

import logging
import sys
from time import perf_counter
from typing import Any, cast
from uuid import uuid4

from fastapi import Request, Response
from pythonjsonlogger import json as jsonlogger

from urgs_deepagents_service.sse import sanitize_text

LOG_FORMAT = (
    "%(asctime)s %(levelname)s %(name)s %(message)s %(request_id)s "
    "%(path)s %(method)s %(status_code)s %(duration_ms)s"
)


def setup_logging(log_level: str) -> None:
    root = logging.getLogger()
    root.handlers.clear()
    handler = logging.StreamHandler(sys.stdout)
    handler.setFormatter(jsonlogger.JsonFormatter(LOG_FORMAT))
    root.addHandler(handler)
    root.setLevel(getattr(logging, log_level.upper(), logging.INFO))


async def request_context_middleware(request: Request, call_next: Any) -> Response:
    request_id = request.headers.get("X-Request-ID") or uuid4().hex
    request.state.request_id = request_id
    logger = logging.getLogger("urgs_deepagents_service.http")
    started = perf_counter()
    extra = {
        "request_id": request_id,
        "path": request.url.path,
        "method": request.method,
        "status_code": None,
        "duration_ms": None,
    }
    logger.info("request_started", extra=extra)
    try:
        response = cast(Response, await call_next(request))
    except Exception as exc:
        duration_ms = round((perf_counter() - started) * 1000, 2)
        logger.exception(
            "request_failed",
            extra={
                **extra,
                "status_code": 500,
                "duration_ms": duration_ms,
                "error": sanitize_text(exc),
            },
        )
        raise
    duration_ms = round((perf_counter() - started) * 1000, 2)
    response.headers["X-Request-ID"] = request_id
    logger.info(
        "request_completed",
        extra={
            **extra,
            "status_code": response.status_code,
            "duration_ms": duration_ms,
        },
    )
    return response
