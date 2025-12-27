import asyncio
from typing import Any, Awaitable, Callable, Dict, Optional

from core.errors import ToolExecutionError
from core.logging import get_logger

ToolCallable = Callable[..., Awaitable[Any]]


class ToolExecutor:
    def __init__(self, timeout_s: int = 30, max_retries: int = 2):
        self.timeout_s = timeout_s
        self.max_retries = max_retries
        self.logger = get_logger("tool-executor")

    async def execute(self, tool: ToolCallable, args: Optional[Dict[str, Any]] = None) -> Any:
        args = args or {}
        for attempt in range(self.max_retries + 1):
            try:
                return await asyncio.wait_for(tool(**args), timeout=self.timeout_s)
            except Exception as exc:  # pragma: no cover - 兜底记录
                self.logger.error("tool_execution_failed", attempt=attempt, error=str(exc))
                if attempt >= self.max_retries:
                    raise ToolExecutionError(f"工具执行失败: {exc}") from exc
