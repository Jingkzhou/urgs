from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_prefix="DEEPAGENTS_", env_file=".env", extra="ignore", case_sensitive=False
    )

    service_name: str = "urgs-deepagents"
    environment: str = "development"
    host: str = "0.0.0.0"
    port: int = 8003
    log_level: str = "INFO"

    urgs_api_url: str = "http://127.0.0.1:8080"
    model: str | None = None
    request_timeout_seconds: float = 600.0
    config_request_timeout_seconds: float = 10.0


@lru_cache
def get_settings() -> Settings:
    return Settings()
