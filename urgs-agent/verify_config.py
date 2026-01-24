from core.config import get_settings
import os

# 模拟加载上层目录的 .env (如果当前目录没有)
if not os.path.exists(".env") and os.path.exists("../.env"):
    from dotenv import load_dotenv

    load_dotenv("../.env")

settings = get_settings()
print(f"Provider: {settings.embedding_model_provider}")
print(f"Model: {settings.embedding_model_name}")
print(f"Base URL: {settings.embedding_base_url}")
print(
    f"API Key: {'***' + settings.embedding_api_key[-4:] if settings.embedding_api_key else 'Missing'}"
)
