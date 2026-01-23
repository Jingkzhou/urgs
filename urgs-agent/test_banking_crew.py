#!/usr/bin/env python
"""
银行核心业务排查系统测试脚本
演示完整的排查流程

用法:
    python test_banking_crew.py
"""

from agent.tools.banking_tools import (
    Search_1104_DB_Tool,
    Search_Core_DB_Tool,
    Search_EAST_DB_Tool,
    Search_YBT_DB_Tool,
)


def test_tools():
    """测试所有银行系统工具"""
    print("=" * 80)
    print("🧪 测试银行系统工具")
    print("=" * 80)

    # 测试 1104 工具
    print("\n【测试 1: 1104监管报送系统】")
    tool_1104 = Search_1104_DB_Tool()
    result = tool_1104._run(table_name="G01_LOAN_INFO", data_id="BATCH_2023_Q3")
    print(result)

    # 测试大集中工具
    print("\n\n【测试 2: 大集中核心系统】")
    tool_core = Search_Core_DB_Tool()
    result = tool_core._run(table_name="ACCT_BALANCE", data_id="6222021234567890")
    print(result)

    # 测试 EAST 工具
    print("\n\n【测试 3: EAST数据报送系统】")
    tool_east = Search_EAST_DB_Tool()
    result = tool_east._run(table_name="EAST_CUSTOMER_INFO", data_id="EAST_202310")
    print(result)

    # 测试一表通工具
    print("\n\n【测试 4: 一表通统一报表系统】")
    tool_ybt = Search_YBT_DB_Tool()
    result = tool_ybt._run(table_name="YBT_DAILY_SUMMARY", data_id="2023-10-31")
    print(result)


def test_intent_classification():
    """测试意图分类功能"""
    from agent.crews import classify_intent, extract_system_name

    print("\n" + "=" * 80)
    print("🧪 测试意图分类与系统识别")
    print("=" * 80)

    test_cases = [
        "1104报表G01_LOAN_INFO贷款余额与总账不符",
        "大集中账户余额与流水不一致",
        "EAST明细数据校验失败",
        "一表通报表显示为0",
        "查询任务状态",  # 应该识别为job而非banking
    ]

    for i, text in enumerate(test_cases, 1):
        intent = classify_intent(text)
        system = extract_system_name(text) if intent == "banking" else "N/A"
        print(f"\n案例 {i}: {text}")
        print(f"  └─ 意图: {intent}")
        if intent == "banking":
            print(f"  └─ 系统: {system}")


def test_crew_creation():
    """测试Crew创建"""
    from agent.crews import URGSCrew

    print("\n" + "=" * 80)
    print("🧪 测试Crew创建")
    print("=" * 80)

    crew_instance = URGSCrew()

    print("\n正在创建银行排查Crew...")
    crew = crew_instance.create_banking_support_crew(
        issue_description="1104报表G01_LOAN_INFO贷款余额合计与总账不符,少了3笔数据",
        system_name="1104",
        table_name="G01_LOAN_INFO",
        data_id="BATCH_2023_Q3",
    )

    print(f"✅ Crew创建成功!")
    print(f"  └─ Agents数量: {len(crew.agents)}")
    print(f"  └─ Tasks数量: {len(crew.tasks)}")
    print(f"  └─ Process模式: {crew.process}")

    # 列出所有Agent
    print(f"\n  Agent列表:")
    for agent in crew.agents:
        print(f"    - {agent.role}")


def main():
    """主函数"""
    print("\n" + "=" * 80)
    print("🏦 银行核心业务排查系统 - 测试套件")
    print("=" * 80)

    try:
        # 测试 1: 工具层
        test_tools()

        # 测试 2: 意图分类
        test_intent_classification()

        # 测试 3: Crew创建
        test_crew_creation()

        print("\n" + "=" * 80)
        print("✅ 所有测试通过!")
        print("=" * 80)
        print("\n💡 下一步:")
        print("   1. 运行完整的Crew执行: crew.kickoff(...)")
        print("   2. 验证PM能正确委派给对应专家")
        print("   3. 验证最终输出为业务友好的回复")
        print("\n⚠️  注意:")
        print("   - Delegation功能依赖LLM能力(建议使用GPT-4或Gemini Pro)")
        print("   - Mock工具返回模拟数据,无真实数据库风险")
        print("=" * 80)

    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
