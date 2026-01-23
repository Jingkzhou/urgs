import os
from openai import OpenAI
from core.config import get_settings


def test_embedding():
    settings = get_settings()
    print(f"Testing Embedding with:")
    print(f"  Base URL: {settings.embedding_base_url}")
    print(f"  API Key: {settings.embedding_api_key[:5]}...")
    print(f"  Model: {settings.embedding_model_name}")

    client = OpenAI(
        base_url=settings.embedding_base_url,
        api_key=settings.embedding_api_key,
    )

    try:
        print("\nSending request...")
        response = client.embeddings.create(
            input="Test sentence", model=settings.embedding_model_name
        )
        print("Success!")
        print(f"Embedding length: {len(response.data[0].embedding)}")
    except Exception as e:
        print(f"\nError: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    test_embedding()
