# CrewAI Task 定义
# URGS 系统任务模板

from crewai import Task
from typing import Optional


def create_analyze_request_task(agent, context: Optional[str] = None) -> Task:
    """
    分析用户请求任务
    由协调员执行，理解用户意图
    """
    return Task(
        description=f"""分析用户的请求，理解其意图和需求。

用户请求: {{user_input}}

{f"附加上下文: {context}" if context else ""}

请判断：
1. 用户想要完成什么操作？
2. 需要调用哪些功能（知识检索/血缘分析/任务管理）？
3. 是否有潜在的风险操作需要注意？

基于分析结果，规划下一步行动。""",
        expected_output="对用户请求的理解分析，包含意图判断和行动计划",
        agent=agent,
    )


def create_rag_query_task(agent, question: str = None) -> Task:
    """
    知识库检索任务
    由 RAG 专家执行
    """
    return Task(
        description=f"""从知识库中检索与问题相关的信息。

问题: {question or "{user_input}"}

使用 RAG 知识检索工具查询相关内容，整理并返回清晰的答案。
如果找不到相关信息，请明确告知用户。""",
        expected_output="基于知识库检索的回答，包含相关引用来源",
        agent=agent,
    )


def create_lineage_analysis_task(agent, sql: str = None) -> Task:
    """
    SQL 血缘分析任务
    由血缘分析师执行
    """
    return Task(
        description=f"""分析 SQL 语句的血缘关系。

SQL: {sql or "{sql_input}"}

使用 SQL 血缘分析工具解析该 SQL，提取：
1. 涉及的源表和目标表
2. 字段级别的映射关系
3. 数据流向说明

以清晰的格式返回分析结果。""",
        expected_output="SQL 血缘分析报告，包含表关系和字段映射",
        agent=agent,
    )


def create_table_impact_task(agent, table_name: str = None) -> Task:
    """
    表影响分析任务
    分析修改某表可能影响的下游
    """
    return Task(
        description=f"""分析表的影响范围。

表名: {table_name or "{table_name}"}

使用血缘查询工具分析该表的上下游关系：
1. 哪些表依赖这张表（下游）？
2. 这张表依赖哪些表（上游）？
3. 如果修改这张表，可能影响多大范围？

提供清晰的影响范围评估。""",
        expected_output="表的影响范围分析报告",
        agent=agent,
    )


def create_job_status_task(agent) -> Task:
    """
    任务状态查询
    由执行者查询任务列表和状态
    """
    return Task(
        description="""查询当前的调度任务状态。

使用任务查询工具获取任务列表，汇总以下信息：
1. 正在运行的任务数量
2. 最近失败的任务
3. 待执行的任务

以简洁的格式呈现任务状态概览。""",
        expected_output="任务状态概览报告",
        agent=agent,
    )


def create_execute_job_task(agent, job_id: str = None, job_name: str = None) -> Task:
    """
    任务执行触发
    由执行者触发任务执行
    """
    job_desc = job_name or job_id or "{job_id}"
    return Task(
        description=f"""触发任务执行。

任务标识: {job_desc}

步骤：
1. 首先确认任务存在并获取详情
2. 检查任务当前状态是否可以执行
3. 触发任务执行
4. 返回执行结果

注意：这是一个写操作，请确保操作正确。""",
        expected_output="任务触发执行的结果报告",
        agent=agent,
    )


def create_summary_task(agent, context: str = None) -> Task:
    """
    汇总回答任务
    由协调员汇总所有结果
    """
    return Task(
        description=f"""汇总所有专家的分析结果，生成最终回答。

{f"上下文: {context}" if context else ""}

基于前面各专家的工作结果：
1. 提取关键信息
2. 组织成清晰的回答
3. 如有必要，提供后续建议

使用用户友好的语言回答。""",
        expected_output="对用户请求的完整回答",
        agent=agent,
    )


def create_sql_query_task(agent, user_input: str = None) -> Task:
    """
    业务数据查询任务
    由数据分析师执行
    """
    return Task(
        description=f"""根据用户的业务问题，查询数据库并提供答案。

用户问题: {user_input or "{user_input}"}

请执行：
1. 分析问题，推导出需要的 SQL 查询（基于已知表结构）
   (主要表: task_info, task_schedule, task_execution_log 等)
2. 使用业务数据查询工具执行 SQL
3. 根据查询结果，回答用户问题

注意：只回答与数据相关的事实，不要臆测。""",
        expected_output="基于数据库查询结果的业务问题回答",
        agent=agent,
    )


def create_data_quality_check_task(agent, table_name: str = None) -> Task:
    """
    数据质量检查任务
    由数据分析师执行
    """
    return Task(
        description=f"""检查表 {table_name or "{table_name}"} 的数据质量问题。

使用"数据质量检查"工具执行检查，分析：
1. 总行数和字段数
2. 各字段的 NULL 值分布
3. 是否存在异常模式

返回数据质量问题清单。""",
        expected_output="数据质量检查报告，包含 NULL 值统计和异常发现",
        agent=agent,
    )


def create_root_cause_summary_task(agent, context: list = None) -> Task:
    """
    根因分析汇总任务
    由协调员执行，基于多个专家的输出
    """
    return Task(
        description="""根据各专家的分析结果，进行根因推断。

你将获得以下信息：
- 数据质量检查结果（NULL 值、异常）
- 表血缘关系（上下游依赖）
- 历史问题参考（知识库检索）

请：
1. 综合分析所有信息
2. 推断最可能的根因
3. 给出修复建议

输出结构化的根因分析报告。""",
        expected_output="根因分析报告，包含问题定位、可能原因和修复建议",
        agent=agent,
        context=context,  # 依赖前面任务的输出
    )
