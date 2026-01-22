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
)
from agent.tools import (
    get_rag_tools,
    get_lineage_tools,
    get_executor_tools,
    get_sql_tool,
    get_data_quality_tools,
    get_all_tools,
)
from core.logging import get_logger

logger = get_logger("crew")


class URGSCrew:
    """
    URGS 智能助手 Crew
    根据用户请求类型自动编排 Agent 协作
    """

    def __init__(self):
        # 初始化 Agents（带工具）
        self.coordinator = create_coordinator_agent(tools=get_all_tools())
        self.rag_expert = create_rag_expert_agent(tools=get_rag_tools())
        self.lineage_analyst = create_lineage_analyst_agent(tools=get_lineage_tools())
        self.executor = create_executor_agent(tools=get_executor_tools())
        self.data_analyst = create_data_analyst_agent(tools=[get_sql_tool()])

    def create_general_crew(self, user_input: str) -> Crew:
        """
        创建通用问答 Crew
        使用分层协作模式，由协调员统领
        """
        analyze_task = create_analyze_request_task(self.coordinator)
        summary_task = create_summary_task(self.coordinator)

        return Crew(
            agents=[
                self.coordinator,
                self.rag_expert,
                self.lineage_analyst,
                self.executor,
                self.data_analyst,
            ],
            tasks=[analyze_task, summary_task],
            process=Process.hierarchical,
            manager_agent=self.coordinator,
            verbose=True,
        )

    def create_rag_crew(self, question: str) -> Crew:
        """
        创建 RAG 知识检索 Crew
        专注知识库查询场景
        """
        query_task = create_rag_query_task(self.rag_expert, question)

        return Crew(
            agents=[self.rag_expert],
            tasks=[query_task],
            process=Process.sequential,
            verbose=True,
        )

    def create_lineage_crew(self, sql: str = None, table_name: str = None) -> Crew:
        """
        创建血缘分析 Crew
        用于 SQL 解析和表影响分析
        """
        tasks = []

        if sql:
            tasks.append(create_lineage_analysis_task(self.lineage_analyst, sql))

        if table_name:
            tasks.append(create_table_impact_task(self.lineage_analyst, table_name))

        if not tasks:
            # 默认分析任务
            tasks.append(create_lineage_analysis_task(self.lineage_analyst))

        return Crew(
            agents=[self.lineage_analyst],
            tasks=tasks,
            process=Process.sequential,
            verbose=True,
        )

    def create_data_analysis_crew(self, user_input: str) -> Crew:
        """
        创建数据分析 Crew
        负责执行 NL2SQL 查询业务数据
        """
        task = create_sql_query_task(self.data_analyst, user_input)
        return Crew(
            agents=[self.data_analyst],
            tasks=[task],
            process=Process.sequential,
            verbose=True,
        )

    def create_job_management_crew(
        self, job_id: str = None, action: str = "status"
    ) -> Crew:
        """
        创建任务管理 Crew
        用于任务查询和执行
        """
        tasks = []

        if action == "trigger" and job_id:
            tasks.append(create_execute_job_task(self.executor, job_id=job_id))
        else:
            tasks.append(create_job_status_task(self.executor))

        return Crew(
            agents=[self.executor],
            tasks=tasks,
            process=Process.sequential,
            verbose=True,
        )

    def create_data_quality_crew(self, table_name: str) -> Crew:
        """
        数据质量根因分析 Crew
        4 个 Agent 协作完成
        """
        # 为 hierarchical 模式创建不带工具的 manager agent
        from agent.agents import create_coordinator_agent

        manager = create_coordinator_agent(tools=[])  # Manager 不能有工具

        # Step 1: 数据分析师检查数据质量
        quality_check_task = create_data_quality_check_task(
            self.data_analyst, table_name
        )

        # Step 2: 血缘分析师查上游依赖
        lineage_task = create_table_impact_task(self.lineage_analyst, table_name)

        # Step 3: RAG 专家查历史问题
        rag_task = create_rag_query_task(
            self.rag_expert, f"{table_name} 历史数据问题 质量"
        )

        # Step 4: 协调员汇总根因分析
        summary_task = create_root_cause_summary_task(
            manager, context=[quality_check_task, lineage_task, rag_task]
        )

        return Crew(
            agents=[
                self.data_analyst,
                self.lineage_analyst,
                self.rag_expert,
            ],
            tasks=[quality_check_task, lineage_task, rag_task, summary_task],
            process=Process.hierarchical,
            manager_agent=manager,
            verbose=True,
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

    # 简单意图分类（后续可用 LLM 增强）
    intent = classify_intent(user_input)
    logger.info("intent_classified", intent=intent)

    # 根据意图选择 Crew
    if intent == "rag":
        crew = crew_instance.create_rag_crew(user_input)
    elif intent == "lineage":
        crew = crew_instance.create_lineage_crew(sql=extract_sql(user_input))
    elif intent == "data":
        crew = crew_instance.create_data_analysis_crew(user_input)
    elif intent == "quality":
        table_name = extract_table_name(user_input) or "unknown_table"
        crew = crew_instance.create_data_quality_crew(table_name)
    elif intent == "job":
        crew = crew_instance.create_job_management_crew()
    else:
        crew = crew_instance.create_general_crew(user_input)

    # 执行 Crew
    inputs = {"user_input": user_input}
    if context:
        inputs.update(context)

    result = crew.kickoff(inputs=inputs)

    logger.info("crew_completed")
    return result.raw if hasattr(result, "raw") else str(result)


def classify_intent(user_input: str) -> str:
    """
    简单意图分类
    后续可升级为 LLM 分类
    """
    user_input_lower = user_input.lower()

    # 血缘相关关键词
    lineage_keywords = [
        "血缘",
        "lineage",
        "sql",
        "解析",
        "表关系",
        "字段",
        "上游",
        "下游",
        "影响",
    ]
    if any(kw in user_input_lower for kw in lineage_keywords):
        return "lineage"

    # 任务管理关键词
    job_keywords = ["任务", "调度", "执行", "job", "运行", "触发", "状态"]
    if any(kw in user_input_lower for kw in job_keywords):
        return "job"

    # 知识检索关键词
    rag_keywords = ["什么是", "怎么", "如何", "为什么", "查询", "找", "搜索", "文档"]
    if any(kw in user_input_lower for kw in rag_keywords):
        return "rag"

    # 数据分析关键词
    data_keywords = [
        "统计",
        "多少",
        "分布",
        "top",
        "排名",
        "总数",
        "count",
        "sum",
    ]
    if any(kw in user_input_lower for kw in data_keywords):
        return "data"

    # 数据质量分析关键词
    quality_keywords = ["数据质量", "质检", "检查", "null", "异常", "根因", "问题"]
    if any(kw in user_input_lower for kw in quality_keywords):
        return "quality"

    return "general"


def extract_sql(user_input: str) -> Optional[str]:
    """
    从用户输入中提取 SQL 语句
    """
    import re

    # 尝试匹配常见 SQL 模式
    sql_patterns = [
        r"(SELECT\s+.+)",
        r"(INSERT\s+.+)",
        r"(UPDATE\s+.+)",
        r"(CREATE\s+.+)",
        r"(DELETE\s+.+)",
    ]

    for pattern in sql_patterns:
        match = re.search(pattern, user_input, re.IGNORECASE | re.DOTALL)
        if match:
            return match.group(1).strip()

    return None


def extract_table_name(user_input: str) -> Optional[str]:
    """
    从用户输入中提取表名
    """
    import re

    # 尝试匹配常见表名模式
    patterns = [
        r"表\s*[`'\"]?(\w+)[`'\"]?",  # 表 xxx
        r"[`'\"](\w+)[`'\"]?\s*表",  # xxx 表
        r"table\s+(\w+)",  # table xxx
        r"(\w+)\s+table",  # xxx table
    ]

    for pattern in patterns:
        match = re.search(pattern, user_input, re.IGNORECASE)
        if match:
            return match.group(1)

    return None
