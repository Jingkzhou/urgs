from typing import List, Optional

from langchain_core.messages import BaseMessage
from langchain_openai import ChatOpenAI

from core.config import Settings, get_settings


class LLMClient:
    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()
        self._client = ChatOpenAI(
            base_url=self.settings.openai_base_url,
            api_key=self.settings.openai_api_key,
            model=self.settings.model_name,
            temperature=self.settings.llm_temperature,
            timeout=self.settings.llm_timeout_s,
        )

    async def chat(self, messages: List[BaseMessage]) -> BaseMessage:
        return await self._client.ainvoke(messages)
