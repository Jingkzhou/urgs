from functools import lru_cache
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_prefix="", case_sensitive=False)

    openai_base_url: str = Field("http://localhost:11434/v1", validation_alias="OPENAI_BASE_URL")
    openai_api_key: str = Field("dummy", validation_alias="OPENAI_API_KEY")
    model_name: str = Field("qwen3", validation_alias="MODEL_NAME")
    llm_temperature: float = Field(0.3, validation_alias="LLM_TEMPERATURE")
    llm_timeout_s: int = Field(60, validation_alias="LLM_TIMEOUT_S")

    mcp_servers: List[str] = Field(default_factory=list, validation_alias="MCP_SERVERS")
    allowlist_tools: List[str] = Field(default_factory=list, validation_alias="ALLOWLIST_TOOLS")
    tool_timeout_s: int = Field(30, validation_alias="TOOL_TIMEOUT_S")
    tool_max_retries: int = Field(2, validation_alias="TOOL_MAX_RETRIES")
    tool_budget_max_calls: int = Field(8, validation_alias="TOOL_BUDGET_MAX_CALLS")

    session_store: str = Field("memory", validation_alias="SESSION_STORE")
    redis_url: Optional[str] = Field(default=None, validation_alias="REDIS_URL")
    mysql_dsn: Optional[str] = Field(default=None, validation_alias="MYSQL_DSN")
    audit_enabled: bool = Field(True, validation_alias="AUDIT_ENABLED")

    require_approval_for_side_effect: bool = Field(True, validation_alias="REQUIRE_APPROVAL_FOR_SIDE_EFFECT")
    mask_sensitive_fields: bool = Field(True, validation_alias="MASK_SENSITIVE_FIELDS")


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
