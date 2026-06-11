import asyncio
import json
import uuid
from collections.abc import AsyncIterator, Awaitable
from typing import Any, cast

from redis.asyncio import Redis

from urgs_agent.config import Settings


class RedisBroker:
    def __init__(self, client: Redis, settings: Settings) -> None:
        self.client = client
        self.settings = settings

    async def enqueue(self, run_id: uuid.UUID) -> None:
        await cast(Awaitable[int], self.client.lpush(self.settings.queue_name, str(run_id)))

    async def dequeue(self) -> uuid.UUID | None:
        item = await cast(
            Awaitable[list[Any] | None],
            self.client.brpop(
                [self.settings.queue_name], timeout=self.settings.worker_poll_seconds
            ),
        )
        if item is None:
            return None
        return uuid.UUID(item[1].decode())

    async def acquire_thread(self, thread_id: str, run_id: uuid.UUID) -> bool:
        return bool(
            await self.client.set(
                f"urgs-agent:thread-lock:{thread_id}",
                str(run_id),
                ex=self.settings.lock_ttl_seconds,
                nx=True,
            )
        )

    async def release_thread(self, thread_id: str, run_id: uuid.UUID) -> None:
        key = f"urgs-agent:thread-lock:{thread_id}"
        script = """
        if redis.call('get', KEYS[1]) == ARGV[1] then
          return redis.call('del', KEYS[1])
        end
        return 0
        """
        await cast(Awaitable[Any], self.client.eval(script, 1, key, str(run_id)))

    async def request_cancel(self, run_id: uuid.UUID) -> None:
        await self.client.set(f"urgs-agent:cancel:{run_id}", "1", ex=86400)

    async def is_cancelled(self, run_id: uuid.UUID) -> bool:
        return bool(await self.client.exists(f"urgs-agent:cancel:{run_id}"))

    async def publish_event(self, run_id: uuid.UUID, event: dict[str, object]) -> None:
        channel = f"{self.settings.event_channel_prefix}:{run_id}"
        await cast(Awaitable[int], self.client.publish(channel, json.dumps(event, default=str)))

    async def subscribe(self, run_id: uuid.UUID) -> AsyncIterator[dict[str, object]]:
        pubsub = self.client.pubsub()
        channel = f"{self.settings.event_channel_prefix}:{run_id}"
        await pubsub.subscribe(channel)
        try:
            while True:
                message = await pubsub.get_message(ignore_subscribe_messages=True, timeout=1)
                if message is not None:
                    yield json.loads(message["data"])
                else:
                    yield {}
                    await asyncio.sleep(0.1)
        finally:
            await pubsub.unsubscribe(channel)
            await cast(Any, pubsub).aclose()
