import hashlib
import hmac
import json
import uuid

import httpx
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from urgs_agent.config import Settings
from urgs_agent.storage.models import CallbackDeliveryModel, RunModel


class CallbackDispatcher:
    def __init__(self, settings: Settings, factory: async_sessionmaker[AsyncSession]) -> None:
        self.settings = settings
        self.factory = factory

    async def deliver(self, run: RunModel, payload: dict[str, object]) -> None:
        if not run.callback_url:
            return
        body = json.dumps(payload, ensure_ascii=False, default=str).encode()
        signature = hmac.new(
            self.settings.callback_hmac_secret.encode(), body, hashlib.sha256
        ).hexdigest()
        async with httpx.AsyncClient(timeout=15) as client:
            for attempt in range(1, self.settings.callback_max_attempts + 1):
                status_code: int | None = None
                error: str | None = None
                success = False
                try:
                    response = await client.post(
                        run.callback_url,
                        content=body,
                        headers={
                            "Content-Type": "application/json",
                            "X-URGS-Signature": f"sha256={signature}",
                            "X-Request-Id": run.request_id,
                        },
                    )
                    status_code = response.status_code
                    success = response.is_success
                    if success:
                        await self._record(run.run_id, attempt, status_code, True, None)
                        return
                    error = response.text[:2000]
                except Exception as exc:
                    error = str(exc)
                await self._record(run.run_id, attempt, status_code, False, error)

    async def _record(
        self,
        run_id: uuid.UUID,
        attempt: int,
        status_code: int | None,
        success: bool,
        error: str | None,
    ) -> None:
        async with self.factory() as session, session.begin():
            session.add(
                CallbackDeliveryModel(
                    run_id=run_id,
                    url="redacted",
                    attempt=attempt,
                    status_code=status_code,
                    success=success,
                    error=error,
                )
            )
