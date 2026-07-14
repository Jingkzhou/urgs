"""复杂监管影响评估的覆盖复核与最小检索规则。"""

from __future__ import annotations

REGULATORY_KNOWLEDGE_AGENT_CODE = "regulatory-knowledge-agent"
REGULATORY_SCENARIO_MAP_PATH = "/04-综合/监管业务场景-报送映射.md"

_IMPACT_INTENT_TERMS = (
    "影响",
    "评估",
    "分析",
    "涉及",
    "纳入",
    "排除",
    "上线",
    "变更",
    "改造",
    "新增",
)
_REGULATORY_SCOPE_TERMS = (
    "监管系统",
    "监管报表",
    "监管指标",
    "监管报送",
    "报送系统",
    "报表",
    "口径",
)


def requires_regulatory_coverage_review(agent_code: str, user_message: str) -> bool:
    """识别需要跨系统覆盖复核的监管知识任务。"""

    if agent_code != REGULATORY_KNOWLEDGE_AGENT_CODE:
        return False
    text = user_message.strip()
    return any(term in text for term in _IMPACT_INTENT_TERMS) and any(
        term in text for term in _REGULATORY_SCOPE_TERMS
    )


def build_regulatory_coverage_task(user_message: str) -> str:
    """生成只读覆盖复核任务，供监管知识 Worker 独立查漏。"""

    return (
        "执行监管影响覆盖复核。不要只复述前序答案，要使用只读检索工具独立检查是否遗漏"
        "监管系统、报表和指标。先用用户原始业务词及同义词定向检索 04-综合、02-主题、"
        "03-实体，再读取新增候选的直接证据页。逐项核对账户与分户账、交易与发生额、"
        "余额与存量、资产负债、流动性期限/LCR/NSFR、集中度与同业敞口、利率重定价等"
        "维度。任何明确排除项都必须有已读取页面或定向检索结果支撑；证据不足时改为"
        "待确认。输出精简的‘遗漏补充、排除校正、覆盖结论’，供最终汇总使用。\n\n"
        f"原始用户任务：\n{user_message}"
    )


def regulatory_retrieval_requirements(user_message: str) -> list[tuple[str, dict[str, str]]]:
    """返回影响评估在给出答案前必须完成的最小检索动作。"""

    requirements: list[tuple[str, dict[str, str]]] = [
        ("read_file", {"file_path": REGULATORY_SCENARIO_MAP_PATH}),
    ]
    if "同业存放" in user_message:
        requirements.extend(
            [
                (
                    "grep",
                    {
                        "pattern": "同业存放",
                        "path": "/",
                        "glob": "*.md",
                        "output_mode": "files_with_matches",
                    },
                ),
                (
                    "read_file",
                    {"file_path": "/02-主题/同业存放-监管报送映射.md"},
                ),
                (
                    "read_file",
                    {
                        "file_path": (
                            "/03-实体/EAST5.0-IE_004_405-对公存款分户账.md"
                        )
                    },
                ),
            ]
        )
    return requirements
