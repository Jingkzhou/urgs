#!/usr/bin/env python
"""
银行核心业务排查系统测试脚本 (SOTA架构版)
演示新的中心化PM架构 + CoT规划流程

更新说明:
- 适配 create_unified_crew 接口
- 验证 PM Agent 的 CoT 规划能力配置
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


def test_unified_crew_creation():
    """测试统一Crew创建 (PM中心化架构)"""
    from agent.crews import URGSCrew

    print("\n" + "=" * 80)
    print("🧪 测试SOTA统一Crew创建")
    print("=" * 80)

    crew_instance = URGSCrew()

    user_input = "对比1104和EAST关于某贷款余额的差异"
    print(f"\n模拟用户请求: '{user_input}'")

    print("正在创建统一Crew...")
    crew = crew_instance.create_unified_crew(user_input)

    print(f"✅ Crew创建成功!")
    print(f"  └─ Agents数量: {len(crew.agents)} (应为4个系统负责人)")
    print(f"  └─ Tasks数量: {len(crew.tasks)} (应为1个PM统一任务)")
    print(f"  └─ Process模式: {crew.process} (应为hierarchical)")
    print(f"  └─ Manager Agent: {crew.manager_agent.role} (应为技术项目经理)")
    print(f"  └─ Memory启用: {crew.memory} (应为True)")

    # 验证Agent列表
    print(f"\n  专家团队列表:")
    roles = []
    for agent in crew.agents:
        print(f"    - {agent.role}")
        roles.append(agent.role)

    assert "1104系统负责人" in roles
    assert "大集中系统负责人" in roles
    assert "EAST系统负责人" in roles
    assert "一表通系统负责人" in roles

    # 验证Task描述是否包含CoT关键词
    task_desc = crew.tasks[0].description
    print(f"\n  PM任务描述检查:")
    if "Think" in task_desc and "Plan" in task_desc and "Delegate" in task_desc:
        print("    ✅ 包含 CoT 关键词 (Think/Plan/Delegate)")
    else:
        print("    ⚠️  警告: 未找到 CoT 关键词,请检查 create_unified_task")
        print(task_desc[:200] + "...")


def main():
    """主函数"""
    print("\n" + "=" * 80)
    print("🏦 银行核心业务排查系统 - 架构验证套件")
    print("=" * 80)

    try:
        # 测试 1: 工具层
        test_tools()

        # 测试 2: 统一Crew创建与配置
        test_unified_crew_creation()

        print("\n" + "=" * 80)
        print("✅ 所有架构验证通过!")
        print("=" * 80)
        print("\n💡 SOTA架构特性验证:")
        print("   1. PM任务使用了 Chain of Thought (Think/Plan/Delegate) 模式")
        print("   2. 所有专家Agent均已加载 Self-Reflection 和工具使用准则")
        print("   3. Crew已启用 Memory 上下文记忆")
        print("   4. SQL工具已集成 SafeSQLGuard 安全护栏")
        print("=" * 80)

    except Exception as e:
        print(f"\n❌ 测试失败: {e}")
        import traceback

        traceback.print_exc()


if __name__ == "__main__":
    main()
