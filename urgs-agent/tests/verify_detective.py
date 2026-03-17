import sys
import os

# Ensure project root is in path
sys.path.append("/Users/work/Documents/GitHub/urgs/urgs-agent")

from agent.crews import classify_intent, URGSCrew
from agent.detective_agents import create_investigation_lead_agent


def test_intent_classification():
    print("Testing Intent Classification...")
    test_cases = [
        ("为什么查不到订单 123 的数据？", "investigate"),
        ("查询 users 表的血缘", "lineage"),
        ("统计一下昨天的任务数", "data"),
        (
            "任务 1001 为什么没跑？",
            "investigate",
        ),  # 包含“为什么”和“任务”，关键词优先级？ "job" vs "investigate"
        # 修正：job 关键词有 "任务", "job"。investigate 有 "为什么".
        # 当前逻辑：check investigate -> check lineage -> check job.
        # "任务 1001 为什么没跑" -> contains "任务" (job) and "为什么" (investigate).
        # 根据代码顺序：
        # 1. investigate_keywords check. "为什么" in input? Yes.
        # 2. "什么是" check? No.
        # So it should be "investigate".
        ("数据质量检查 users 表", "quality"),
        ("什么是 RAG？", "rag"),
    ]

    for input_text, expected in test_cases:
        result = classify_intent(input_text)
        status = "✅" if result == expected else f"❌ (Got {result})"
        print(f"Input: '{input_text}' -> Expected: {expected} -> {status}")


def test_crew_creation():
    print("\nTesting Crew Creation...")
    try:
        crew_instance = URGSCrew()
        crew = crew_instance.create_data_detective_crew("测试意图")
        print("✅ create_data_detective_crew() successful.")

        # Verify agents
        agents = crew.agents
        roles = [a.role for a in agents]
        print(f"Agents: {roles}")

        expected_roles = ["排查指挥官", "SQL专家与元数据顾问", "现场取证员"]
        if all(r in roles for r in expected_roles):
            print("✅ All expected agents are present.")
        else:
            print(f"❌ Missing agents. Found: {roles}")

        # Verify execution process
        if crew.process == "hierarchical":
            print("✅ Process is hierarchical.")
        else:
            print(f"❌ Process is {crew.process}, expected hierarchical.")

    except Exception as e:
        print(f"❌ Failed to create crew: {e}")


if __name__ == "__main__":
    test_intent_classification()
    test_crew_creation()
