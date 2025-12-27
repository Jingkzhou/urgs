import logging
from typing import Any, Dict

import structlog

_logging_configured = False


def setup_logging() -> None:
    global _logging_configured
    if _logging_configured:
        return

    logging.basicConfig(level=logging.INFO, format="%(message)s")
    structlog.configure(
        processors=[
            structlog.processors.add_log_level,
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.JSONRenderer(),
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        cache_logger_on_first_use=True,
    )
    _logging_configured = True


def mask_sensitive_fields(payload: Dict[str, Any], mask: str = "***") -> Dict[str, Any]:
    redacted_keys = {"password", "token", "api_key", "authorization"}
    return {k: (mask if k.lower() in redacted_keys else v) for k, v in payload.items()}


def get_logger(name: str = "urgs-agent") -> structlog.stdlib.BoundLogger:
    setup_logging()
    return structlog.get_logger(name)
