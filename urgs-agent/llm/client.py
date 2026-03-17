# LLM 客户端 - CrewAI 版本
# 该模块现在主要用于向后兼容，CrewAI 自带 LLM 集成

from typing import Optional

from core.config import Settings, get_settings


class LLMClient:
    """
    LLM 客户端（向后兼容）
    CrewAI 版本不再使用此类进行主要 LLM 交互。
    保留此类是为了可能的独立 LLM 调用需求。
    """

    def __init__(self, settings: Optional[Settings] = None):
        self.settings = settings or get_settings()
        self._model = self.settings.model_name
        self._base_url = self.settings.openai_base_url
        self._api_key = self.settings.openai_api_key

    def get_model_info(self) -> dict:
        """获取模型配置信息"""
        return {
            "model": self._model,
            "base_url": self._base_url,
            "temperature": self.settings.llm_temperature,
            "timeout": self.settings.llm_timeout_s,
        }
