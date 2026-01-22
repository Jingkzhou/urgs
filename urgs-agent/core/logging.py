import logging
from typing import Any, Dict

import structlog

_logging_configured = False


def setup_logging() -> None:
    global _logging_configured
    if _logging_configured:
        return

    logging.basicConfig(level=logging.INFO, format="%(message)s")

    # 配置日志文件输出
    import os
    from logging.handlers import RotatingFileHandler

    os.makedirs("logs", exist_ok=True)
    file_handler = RotatingFileHandler(
        "logs/urgs_agent.log",
        maxBytes=10 * 1024 * 1024,  # 10MB
        backupCount=5,
        encoding="utf-8",
    )
    file_handler.setFormatter(
        logging.Formatter("%(asctime)s - %(name)s - %(levelname)s - %(message)s")
    )
    logging.getLogger().addHandler(file_handler)

    # 捕获 CrewAI 和其他库的日志
    logging.getLogger("crewai").setLevel(logging.INFO)
    logging.getLogger("httpcore").setLevel(logging.WARNING)
    logging.getLogger("httpx").setLevel(logging.WARNING)

    # LiteLLM 日志
    logging.getLogger("LiteLLM").setLevel(logging.INFO)
    logging.getLogger("LiteLLM").addHandler(file_handler)

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

    # 重定向 stdout 到日志文件 (捕获 print)
    import sys

    sys.stdout = LoggerWriter(logging.getLogger("stdout"), logging.INFO)
    # sys.stderr = LoggerWriter(logging.getLogger("stderr"), logging.ERROR) # 暂不重定向 stderr，以免掩盖关键错误 traceback

    _logging_configured = True


class LoggerWriter:
    """
    Fake file-like stream that redirects writes to a logger instance.
    """

    def __init__(self, logger, level):
        self.logger = logger
        self.level = level
        self.linebuf = ""

    def write(self, buf):
        for line in buf.rstrip().splitlines():
            self.logger.log(self.level, line.rstrip())

    def flush(self):
        pass

    def isatty(self):
        return False

    @property
    def encoding(self):
        return "utf-8"


def mask_sensitive_fields(payload: Dict[str, Any], mask: str = "***") -> Dict[str, Any]:
    redacted_keys = {"password", "token", "api_key", "authorization"}
    return {k: (mask if k.lower() in redacted_keys else v) for k, v in payload.items()}


def get_logger(name: str = "urgs-agent") -> structlog.stdlib.BoundLogger:
    setup_logging()
    return structlog.get_logger(name)
