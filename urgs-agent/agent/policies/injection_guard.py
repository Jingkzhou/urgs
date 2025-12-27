import re
from typing import Iterable

from core.errors import InjectionDetectedError


class InjectionGuard:
    def __init__(self, patterns: Iterable[str] | None = None):
        base = [
            r"ignore (all|previous) instructions",
            r"reveal (system|hidden) prompt",
            r"disable safety",
            r"drop (database|table)",
            r"shutdown",
        ]
        self.patterns = [re.compile(pat, re.IGNORECASE) for pat in (patterns or base)]

    def is_suspicious(self, text: str) -> bool:
        return any(pat.search(text) for pat in self.patterns)

    def assert_safe(self, text: str) -> None:
        if self.is_suspicious(text):
            raise InjectionDetectedError("检测到疑似提示注入请求", snippet=text[:80])
