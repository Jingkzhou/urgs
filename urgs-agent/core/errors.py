from typing import Optional

from schemas.api import PendingApproval


class AgentError(Exception):
    """基础异常类型，便于统一捕获。"""

    def __init__(self, message: str):
        super().__init__(message)
        self.message = message


class PolicyViolationError(AgentError):
    """策略不允许的行为，如越权工具调用。"""


class ApprovalRequiredError(AgentError):
    """写操作需要人工确认。"""

    def __init__(self, message: str, approval: PendingApproval):
        super().__init__(message)
        self.approval = approval


class ToolExecutionError(AgentError):
    """工具执行异常或超时。"""


class InjectionDetectedError(AgentError):
    """提示注入风险。"""

    def __init__(self, message: str, snippet: Optional[str] = None):
        super().__init__(message)
        self.snippet = snippet
