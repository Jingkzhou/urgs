from __future__ import annotations

from urgs_mcp_server.config import Settings
from urgs_mcp_server.server import create_server
from urgs_mcp_server.urgs_client import UrgsApiClient


def main() -> None:
    settings = Settings.from_env()
    server = create_server(UrgsApiClient(settings))
    server.run(
        transport="streamable-http",
        host=settings.host,
        port=settings.port,
        streamable_http_path="/mcp",
        json_response=True,
    )


if __name__ == "__main__":
    main()
