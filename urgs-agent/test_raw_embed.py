import requests
import json
from core.config import get_settings


def test_raw_request():
    settings = get_settings()
    url = f"{settings.secondary_base_url}/embeddings"
    api_key = settings.secondary_api_key

    # Try removing /v1 if already in base url, to avoid /v1/v1/embeddings if user configured that way
    # But settings.secondary_base_url is http://25.64.32.35:18085/v1
    # so full url is http://25.64.32.35:18085/v1/embeddings

    print(f"URL: {url}")
    print(f"Model: bge-m3")

    headers = {"Authorization": f"Bearer {api_key}", "Content-Type": "application/json"}

    payload = {"input": "test request", "model": "bge-m3"}

    try:
        response = requests.post(url, json=payload, headers=headers, timeout=10)
        print(f"Status Code: {response.status_code}")
        print("Response Text:")
        print(response.text)
    except Exception as e:
        print(f"Error: {e}")


if __name__ == "__main__":
    test_raw_request()
