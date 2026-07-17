from functools import lru_cache

from pydantic import Field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="AGENT_", env_file=".env", extra="ignore", case_sensitive=False
    )

    service_name: str = "urgs-agent"
    environment: str = "development"
    host: str = "0.0.0.0"
    port: int = 8002
    log_level: str = "INFO"

    database_url: str = "postgresql+asyncpg://urgs_agent:urgs_agent@127.0.0.1:5432/urgs_agent"
    checkpoint_database_url: str = "postgresql://urgs_agent:urgs_agent@127.0.0.1:5432/urgs_agent"
    redis_url: str = "redis://127.0.0.1:6379/1"
    queue_name: str = "urgs-agent:runs"
    event_channel_prefix: str = "urgs-agent:events"
    lock_ttl_seconds: int = 900

    api_key: str = ""
    callback_hmac_secret: str = ""
    callback_max_attempts: int = 3

    openai_base_url: str = "http://127.0.0.1:11434/v1"
    openai_api_key: str = "not-set"
    openai_model: str = "qwen3"
    urgs_api_url: str = "http://127.0.0.1:8080"
    lineage_url: str = "http://127.0.0.1:8080"
    http_timeout_seconds: float = 60.0
    knowledge_wiki_root: str = (
        "/Users/zhoujingkun/Documents/GitHub/Obsidian/regulatory-knowledge-vault"
    )
    knowledge_wiki_wiki_dir: str = "."
    knowledge_wiki_raw_dir: str = "01-资料库"
    knowledge_wiki_index_path: str = "00-首页/index.md"
    knowledge_wiki_log_path: str = "05-日志/log.md"
    knowledge_wiki_agent_guide_path: str = "AGENTS.md"
    knowledge_wiki_max_file_bytes: int = 1_000_000
    knowledge_wiki_max_search_files: int = 1000

    worker_poll_seconds: int = 5
    sse_heartbeat_seconds: int = 15
    default_run_timeout_seconds: int = 600
    otlp_endpoint: str | None = None
    trusted_mcp_stdio_servers: dict[str, list[str]] = Field(default_factory=dict)

    @model_validator(mode="after")
    def validate_production_secrets(self) -> "Settings":
        if self.environment.lower() == "production" and not self.api_key:
            raise ValueError("AGENT_API_KEY is required in production")
        return self


@lru_cache
def get_settings() -> Settings:
    return Settings()
