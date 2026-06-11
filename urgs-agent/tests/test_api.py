from fastapi.testclient import TestClient

from urgs_agent.main import app


def test_liveness_does_not_require_dependencies() -> None:
    with TestClient(app) as client:
        response = client.get("/health/live")
    assert response.status_code == 200
    assert response.json() == {"status": "ok"}
