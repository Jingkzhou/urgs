from agent.policies.tool_policy import ToolMetadata, ToolPolicy


def test_tool_policy_allowlist_and_write_detection():
    policy = ToolPolicy()
    tools = [ToolMetadata(name="read_status"), ToolMetadata(name="delete_job", side_effect=True)]
    filtered = policy.filter_allowlist(tools)
    assert len(filtered) == len(tools)  # 默认为空白名单不过滤

    requires = policy.requires_approval(tools[1])
    assert requires is True

    digest = policy.summarize_args({"long": "x" * 300})
    assert digest["long"].endswith("...") is True
