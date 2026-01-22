import os
import requests
from dotenv import load_dotenv

load_dotenv()


def test_embedding_endpoint(base_url, api_key, model_name="text-embedding-3-small"):
    print(f"\n--- Testing Embedding Endpoint: {base_url} ---")
    url = f"{base_url.rstrip('/')}/embeddings"
    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}
    data = {"input": "test connection", "model": model_name}

    try:
        response = requests.post(url, headers=headers, json=data, timeout=5)
        print(f"Status Code: {response.status_code}")
        if response.status_code == 200:
            print("✅ Connection Successful!")
            print(
                f"Embedding vector length: {len(response.json()['data'][0]['embedding'])}"
            )
        else:
            print(f"❌ Connection Failed: {response.text}")
    except Exception as e:
        print(f"🚨 Network Error: {str(e)}")


if __name__ == "__main__":
    # Test 1: Check Environment Variable
    env_base = os.getenv("OPENAI_BASE_URL") or os.getenv("OPENAI_API_BASE")
    env_key = os.getenv("OPENAI_API_KEY")
    if env_base:
        test_embedding_endpoint(env_base, env_key or "dummy", "text-embedding-3-small")
    else:
        print("\n⚠️ OPENAI_BASE_URL not set in env.")

    # Test 2: Check Configured Secondary Base URL
    # Assuming from config.py/env file check
    secondary_base = os.getenv("SECONDARY_BASE_URL", "http://localhost:11434/v1")
    secondary_key = os.getenv("SECONDARY_API_KEY", "dummy")
    test_embedding_endpoint(secondary_base, secondary_key, "text-embedding-3-small")

    # Test 3: Check Primary Base URL (Volcengine)
    primary_base = os.getenv("PRIMARY_BASE_URL")
    primary_key = os.getenv("PRIMARY_API_KEY")
    if primary_base:
        test_embedding_endpoint(
            primary_base, primary_key, "Doubao-embedding"
        )  # Doubao typically needs specific model name
        test_embedding_endpoint(primary_base, primary_key, "doubao-embedding-v1")
        test_embedding_endpoint(
            primary_base,
            primary_key,
            "ep-20250101-example-embedding",  # 示例 access point
        )
