from functools import lru_cache

from pydantic import AliasChoices, Field, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="DEEPAGENTS_", env_file=".env", extra="ignore", case_sensitive=False
    )

    service_name: str = "urgs-deepagents"
    environment: str = "development"
    host: str = "0.0.0.0"
    port: int = Field(default=8003, ge=1, le=65535)
    log_level: str = "INFO"

    urgs_api_url: str = "http://127.0.0.1:8080"
    internal_api_token: str = Field(
        default="",
        validation_alias=AliasChoices("DEEPAGENTS_INTERNAL_API_TOKEN", "URGS_INTERNAL_API_TOKEN"),
    )
    internal_api_auth_header: str = "Authorization"
    internal_api_auth_prefix: str = "Bearer "
    model: str | None = None
    request_timeout_seconds: float = Field(default=600.0, gt=0)
    config_request_timeout_seconds: float = Field(default=10.0, gt=0)
    recursion_limit: int = Field(default=100, ge=25)
    enable_write_tools: bool = False
    workspace_root: str | None = None
    memory_files: str = ""
    skill_dirs: str = ""
    skills_root: str = "skills"

    @field_validator("urgs_api_url")
    @classmethod
    def validate_urgs_api_url(cls, value: str) -> str:
        normalized = value.strip().rstrip("/")
        if not normalized:
            raise ValueError("DEEPAGENTS_URGS_API_URL 不能为空")
        if not normalized.startswith(("http://", "https://")):
            raise ValueError("DEEPAGENTS_URGS_API_URL 必须以 http:// 或 https:// 开头")
        return normalized


@lru_cache
def get_settings() -> Settings:
    return Settings()
