from typing import Any, Protocol

from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

from urgs_agent.storage.models import MemoryModel


class MemoryStore(Protocol):
    async def get(self, namespace: str, key: str) -> dict[str, Any] | None: ...

    async def put(self, namespace: str, key: str, value: dict[str, Any]) -> None: ...


class PostgresMemoryStore:
    def __init__(self, factory: async_sessionmaker[AsyncSession]) -> None:
        self.factory = factory

    async def get(self, namespace: str, key: str) -> dict[str, Any] | None:
        async with self.factory() as session:
            model = await session.scalar(
                select(MemoryModel).where(
                    MemoryModel.namespace == namespace, MemoryModel.memory_key == key
                )
            )
            return model.value if model else None

    async def put(self, namespace: str, key: str, value: dict[str, Any]) -> None:
        async with self.factory() as session, session.begin():
            model = await session.scalar(
                select(MemoryModel).where(
                    MemoryModel.namespace == namespace, MemoryModel.memory_key == key
                )
            )
            if model is None:
                session.add(MemoryModel(namespace=namespace, memory_key=key, value=value))
            else:
                model.value = value
