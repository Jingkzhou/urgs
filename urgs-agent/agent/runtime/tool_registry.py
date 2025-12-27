from typing import Dict, List, Optional

from agent.policies.tool_policy import ToolMetadata
from core.config import Settings, get_settings


class ToolRegistry:
    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()
        self._tools: Dict[str, ToolMetadata] = {}

    async def refresh(self) -> List[ToolMetadata]:
        tools = [ToolMetadata(name=name) for name in self.settings.allowlist_tools]
        self._tools = {tool.name: tool for tool in tools}
        return tools

    def list_tools(self) -> List[ToolMetadata]:
        return list(self._tools.values())

    def get(self, name: str) -> Optional[ToolMetadata]:
        return self._tools.get(name)
