from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    NEO4J_URI: str = "bolt://127.0.0.1:7687"
    NEO4J_USERNAME: str = "neo4j"
    NEO4J_PASSWORD: str = "12345678"
    
    OPENAI_API_KEY: Optional[str] = None
    OPENAI_API_BASE: Optional[str] = None
    OPENAI_MODEL_NAME: str = "qwen-turbo"
    
    LOG_LEVEL: str = "INFO"
    
    URGS_API_URL: str = "http://localhost:8080"

    class Config:
        env_file = ".env"

settings = Settings()
