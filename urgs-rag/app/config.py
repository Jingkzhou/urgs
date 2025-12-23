import os
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    APP_NAME: str = "urgs-rag"
    API_V1_STR: str = "/api/v1"
    
    # ChromaDB 配置
    CHROMA_PERSIST_DIRECTORY: str = os.path.join(os.getcwd(), "data", "chroma_db")
    COLLECTION_NAME: str = "urgs_knowledge_base"
    
    # 存储路径
    DOC_STORAGE_PATH: str = os.path.join(os.getcwd(), "doc_store")
    PARENT_DOC_STORE_PATH: str = os.path.join(os.getcwd(), "data")

    # 向量化（Embedding）配置
    # 选项: "openai", "huggingface", "qwen3"
    EMBEDDING_PROVIDER: str = "huggingface" 
    EMBEDDING_MODEL_NAME: str = "shibing624/text2vec-base-chinese"
    EMBEDDING_DEVICE: str = "cpu"
    
    # LLM 配置（通过环境变量覆盖）
    LLM_API_BASE: str = "http://25.64.32.35:18085/v1"
    LLM_MODEL: str = "qwen3"
    LLM_API_KEY: str = "sk-xxx"

    # Java 后端 API 配置
    URGS_API_BASE_URL: str = "http://localhost:8080"


    class Config:
        env_file = ".env"

settings = Settings()
