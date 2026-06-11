import secrets
from typing import Annotated, cast

from fastapi import Depends, Header, HTTPException, Request, status

from urgs_agent.container import Container


def get_container(request: Request) -> Container:
    return cast(Container, request.app.state.container)


async def require_api_key(
    container: Annotated[Container, Depends(get_container)],
    authorization: Annotated[str | None, Header()] = None,
) -> None:
    expected = container.settings.api_key
    if not expected:
        return
    supplied = authorization.removeprefix("Bearer ") if authorization else ""
    if not secrets.compare_digest(supplied, expected):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="invalid API key")
