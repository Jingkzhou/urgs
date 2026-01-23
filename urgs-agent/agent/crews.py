# CrewAI Crew 定义
# URGS 智能助手 Crew 团队编排

from crewai import Crew, Process
from typing import Dict, Any, Optional

from agent.agents import (
    create_coordinator_agent,
    create_rag_expert_agent,
    create_lineage_analyst_agent,
    create_executor_agent,
    create_data_analyst_agent,
    # 银行系统专家Agents
    create_pm_agent,
    create_1104_expert_agent,
    create_core_banking_expert_agent,
    create_east_expert_agent,
    create_ybt_expert_agent,
)
from agent.detective_agents import (
    create_investigation_lead_agent,
    create_schema_expert_agent,
    create_evidence_collector_agent,
)
from agent.tasks import (
    create_analyze_request_task,
    create_rag_query_task,
    create_lineage_analysis_task,
    create_table_impact_task,
    create_job_status_task,
    create_execute_job_task,
    create_summary_task,
    create_sql_query_task,
    create_data_quality_check_task,
    create_root_cause_summary_task,
    create_investigation_task,
    # 银行排查系统Tasks
    create_triage_investigation_task,
    create_qa_response_task,
)
from agent.tools import (
    get_rag_tools,
    get_lineage_tools,
    get_executor_tools,
    get_sql_tool,
    get_data_quality_tools,
    get_all_tools,
)
from agent.tools.banking_tools import (
    get_1104_tools,
    get_core_banking_tools,
    get_east_tools,
    get_ybt_tools,
)
from core.logging import get_logger

logger = get_logger("crew")


class URGSCrew:
    """
    URGS 智能助手 Crew (中心化PM架构)
    所有请求由PM统一接收并委派给对应系统负责人
    """

    def __init__(self):
        # 极简架构:不再预初始化Agent,在create_unified_crew时动态创建
        pass

    def create_unified_crew(self, user_input: str) -> Crew:
        """
        创建统一Crew - 中心化PM架构
        PM接收所有请求,委派给4个系统负责人之一

        Args:
            user_input: 用户请求

        Returns:
            配置好的Crew实例
        """
        #  1. 创建PM (Manager Agent)
        pm = create_pm_agent()

        # 2. 创建4个系统负责人,每人拥有完整工具集
        from agent.tools import get_sql_tool, get_lineage_tools

        # 1104系统负责人
        expert_1104 = create_1104_expert_agent(
            tools=[
                *get_1104_tools(),  # 1104数据库工具
                *get_1104_rag_tools(),  # 1104知识库工具
                get_sql_tool(),  # SQL执行工具
                *get_lineage_tools(),  # 血缘分析工具
            ]
        )

        # 大集中系统负责人
        expert_core = create_core_banking_expert_agent(
            tools=[
                *get_core_banking_tools(),  # 大集中数据库工具
                *get_core_rag_tools(),  # 大集中知识库工具
                get_sql_tool(),  # SQL执行工具
                *get_lineage_tools(),  # 血缘分析工具
            ]
        )

        # EAST系统负责人
        expert_east = create_east_expert_agent(
            tools=[
                *get_east_tools(),  # EAST数据库工具
                *get_east_rag_tools(),  # EAST知识库工具
                get_sql_tool(),  # SQL执行工具
                *get_lineage_tools(),  # 血缘分析工具
            ]
        )

        # 一表通系统负责人
        expert_ybt = create_ybt_expert_agent(
            tools=[
                *get_ybt_tools(),  # 一表通数据库工具
                *get_ybt_rag_tools(),  # 一表通知识库工具
                get_sql_tool(),  # SQL执行工具
                *get_lineage_tools(),  # 血缘分析工具
            ]
        )

        # 3. 创建PM的统一任务
        from agent.tasks import create_unified_task

        task = create_unified_task(pm, user_input)

        # 4. 组装Crew (Hierarchical模式)
        return Crew(
            agents=[
                expert_1104,  # 所有系统负责人都加入
                expert_core,
                expert_east,
                expert_ybt,
            ],
            tasks=[task],  # 只有一个任务
            process=Process.hierarchical,  # 使用hierarchical模式
            manager_agent=pm,  # PM作为Manager
            verbose=True,
            memory=False,  # 关闭记忆以提升性能
        )


def run_crew(user_input: str, context: Optional[Dict[str, Any]] = None) -> str:
    """
    运行 Crew 处理用户请求

    Args:
        user_input: 用户输入
        context: 可选上下文信息

    Returns:
        Crew 执行结果
    """
    logger.info("crew_started", user_input=user_input[:100])

    crew_instance = URGSCrew()

    # 统一创建Crew,不再需要复杂的意图分类
    # PM会自动识别系统并委派给对应负责人
    crew = crew_instance.create_unified_crew(user_input)

    # 执行 Crew
    inputs = {"user_input": user_input}
    if context:
        inputs.update(context)

    result = crew.kickoff(inputs=inputs)

    logger.info("crew_completed")
    return result.raw if hasattr(result, "raw") else str(result)
