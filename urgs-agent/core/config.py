from functools import lru_cache
from typing import List, Optional

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env", env_prefix="", case_sensitive=False, extra="ignore"
    )

    # Primary Model (大模型 - 协调/汇总/复杂推理)
    # provider: google | openai (可随意搭配，独立于 Secondary)
    primary_model_provider: str = Field(
        "google", validation_alias="PRIMARY_MODEL_PROVIDER"
    )
    primary_model_name: str = Field(
        "gemini-2.0-flash", validation_alias="PRIMARY_MODEL_NAME"
    )
    primary_api_key: str = Field("", validation_alias="PRIMARY_API_KEY")
    primary_base_url: str = Field("", validation_alias="PRIMARY_BASE_URL")

    # Secondary Model (小模型 - 执行层/工具调用)
    # provider: google | openai (可随意搭配，独立于 Primary)
    secondary_model_provider: str = Field(
        "openai", validation_alias="SECONDARY_MODEL_PROVIDER"
    )
    secondary_model_name: str = Field("qwen3", validation_alias="SECONDARY_MODEL_NAME")
    secondary_api_key: str = Field("dummy", validation_alias="SECONDARY_API_KEY")
    secondary_base_url: str = Field(
        "http://localhost:11434/v1", validation_alias="SECONDARY_BASE_URL"
    )

    # LLM 通用配置 (RAG Service / Embedding)
    llm_api_base: str = Field("", validation_alias="LLM_API_BASE")
    llm_model: str = Field("qwen3", validation_alias="LLM_MODEL")
    llm_api_key: str = Field("dummy", validation_alias="LLM_API_KEY")

    llm_temperature: float = Field(0.3, validation_alias="LLM_TEMPERATURE")
    llm_timeout_s: int = Field(60, validation_alias="LLM_TIMEOUT_S")

    # Embeddings Model 配置
    embedding_model_provider: str = Field(
        "openai", validation_alias="Embeddings_MODEL_PROVIDER"
    )
    embedding_model_name: str = Field("qwen3", validation_alias="Embeddings_MODEL_NAME")
    embedding_base_url: str = Field("", validation_alias="Embeddings_BASE_URL")
    embedding_api_key: str = Field("", validation_alias="Embeddings_API_KEY")

    mcp_servers: List[str] = Field(default_factory=list, validation_alias="MCP_SERVERS")
    allowlist_tools: List[str] = Field(
        default_factory=list, validation_alias="ALLOWLIST_TOOLS"
    )
    tool_timeout_s: int = Field(30, validation_alias="TOOL_TIMEOUT_S")
    tool_max_retries: int = Field(2, validation_alias="TOOL_MAX_RETRIES")
    tool_budget_max_calls: int = Field(8, validation_alias="TOOL_BUDGET_MAX_CALLS")

    session_store: str = Field("memory", validation_alias="SESSION_STORE")
    redis_url: Optional[str] = Field(default=None, validation_alias="REDIS_URL")
    # Database Config (MySQL)
    db_host: str = Field("localhost", validation_alias="DB_HOST")
    db_port: int = Field(3306, validation_alias="DB_PORT")
    db_name: str = Field("urgs_dev", validation_alias="DB_NAME")
    db_user: str = Field("root", validation_alias="DB_USER")
    db_password: str = Field("", validation_alias="DB_PASSWORD")

    mysql_dsn: Optional[str] = Field(None, validation_alias="MYSQL_DSN")

    @property
    def get_mysql_dsn(self) -> str:
        if self.mysql_dsn:
            return self.mysql_dsn
        return f"mysql+pymysql://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    audit_enabled: bool = Field(True, validation_alias="AUDIT_ENABLED")

    require_approval_for_side_effect: bool = Field(
        True, validation_alias="REQUIRE_APPROVAL_FOR_SIDE_EFFECT"
    )
    mask_sensitive_fields: bool = Field(True, validation_alias="MASK_SENSITIVE_FIELDS")

    # 服务 URL 配置
    rag_service_url: str = Field(
        "http://localhost:8001", validation_alias="RAG_SERVICE_URL"
    )
    lineage_service_url: str = Field(
        "http://localhost:8002", validation_alias="LINEAGE_SERVICE_URL"
    )
    api_service_url: str = Field(
        "http://localhost:8080", validation_alias="API_SERVICE_URL"
    )


@lru_cache(maxsize=1)
def get_settings() -> Settings:
    return Settings()
