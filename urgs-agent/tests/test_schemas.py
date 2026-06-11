import pytest
from pydantic import ValidationError

from urgs_agent.domain.schemas import WorkflowDefinition


def model() -> dict[str, object]:
    return {"primary": {"provider": "openai_compatible", "model": "test-model"}}


def test_supervisor_requires_two_specialists() -> None:
    with pytest.raises(ValidationError, match="at least two specialists"):
        WorkflowDefinition.model_validate(
            {
                "template": "supervisor",
                "system_prompt": "supervise",
                "model": model(),
                "specialists": [{"id": "one", "description": "one", "system_prompt": "one"}],
            }
        )


def test_limits_reject_unbounded_values() -> None:
    with pytest.raises(ValidationError):
        WorkflowDefinition.model_validate(
            {
                "template": "react",
                "system_prompt": "test",
                "model": model(),
                "limits": {"max_steps": 1000},
            }
        )
