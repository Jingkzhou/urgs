import asyncio
import logging
import signal

from langgraph.checkpoint.postgres.aio import AsyncPostgresSaver

from urgs_agent.config import get_settings
from urgs_agent.container import Container
from urgs_agent.runtime.callbacks import CallbackDispatcher
from urgs_agent.runtime.executor import RunExecutor

logger = logging.getLogger(__name__)


async def run_worker() -> None:
    settings = get_settings()
    container = Container.build(settings)
    stop = asyncio.Event()
    loop = asyncio.get_running_loop()
    for sig in (signal.SIGINT, signal.SIGTERM):
        loop.add_signal_handler(sig, stop.set)
    try:
        async with AsyncPostgresSaver.from_conn_string(
            settings.checkpoint_database_url
        ) as checkpointer:
            await checkpointer.setup()
            executor = RunExecutor(
                container.agents,
                container.runs,
                container.events,
                container.broker,
                container.compiler,
                checkpointer,
                CallbackDispatcher(settings, container.sessions),
            )
            while not stop.is_set():
                run_id = await container.broker.dequeue()
                if run_id is not None:
                    await executor.execute(run_id)
    finally:
        await container.close()


def main() -> None:
    logging.basicConfig(level=get_settings().log_level)
    asyncio.run(run_worker())


if __name__ == "__main__":
    main()
