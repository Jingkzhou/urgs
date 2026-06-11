from typing import Any

import httpx

from urgs_agent.plugins.contracts import Retriever, ToolContext


class UrgsRagRetriever(Retriever):
    name = "urgs_rag"

    def __init__(self, base_url: str, timeout: float = 60) -> None:
        self.base_url = base_url.rstrip("/")
        self.timeout = timeout

    async def search(
        self, query: str, knowledge_bases: list[str], context: ToolContext
    ) -> list[dict[str, Any]]:
        async with httpx.AsyncClient(timeout=self.timeout) as client:
            response = await client.post(
                f"{self.base_url}/api/rag/search",
                json={"query": query, "knowledge_bases": knowledge_bases, "top_k": 8},
                headers={"X-Trace-Id": context.trace_id},
            )
            response.raise_for_status()
            body = response.json()
        raw_items = body.get("results", body if isinstance(body, list) else [])
        return [
            {
                "content": item.get("content", item.get("text", "")),
                "source": item.get("source"),
                "score": item.get("score"),
                "metadata": item.get("metadata", {}),
            }
            for item in raw_items
        ]
