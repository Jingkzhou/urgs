from typing import Annotated, Any, TypedDict

from langchain_core.messages import BaseMessage
from langgraph.graph.message import add_messages


class AgentState(TypedDict, total=False):
    messages: Annotated[list[BaseMessage], add_messages]
    context: dict[str, Any]
    specialist_results: Annotated[list[dict[str, str]], list.__add__]
    final_answer: str
    model_calls: int
    steps: int
