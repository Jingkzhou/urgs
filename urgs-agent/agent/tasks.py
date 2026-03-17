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


def create_investigation_task(agent, user_input: str) -> Task:
    """
    通用数据排查任务
    由排查指挥官（Lead）负责，协调专家进行排查
    """
    return Task(
        description=f"""针对用户反馈的数据问题进行全流程排查。

用户问题: {user_input}

你的职责是带领团队（SQL专家、取证员）找出问题的根因。
你必须遵循以下排查原则：
1. **Schema First**: 不要猜测表名和字段。先让 SQL 专家查询表结构 (DDL)。
2. **Step-by-Step**: 分步排查。先查总数，再查样本，最后查特定条件。
3. **Safe Execution**: 所有的 SQL 执行必须通过"现场取证员"进行。
4. **Data Driven**: 基于查回来的真实数据做判断，而不是基于假设。
5. **Self-Healing Loop**: 如果 SQL 执行报错（如字段不存在），必须指示 SQL 专家分析错误，修正 SQL 并重试,不要就此停止。

建议排查步骤：
1. 分析用户意图,确定涉及的业务实体（如 用户、订单、任务）。
2. 让 SQL 专家找到对应的表结构。
3. 让 SQL 专家构造探测 SQL,并由取证员执行。
4. 分析返回的数据,如果没查到,逐步减少 WHERE 条件,看是哪个条件过滤掉了数据。
5. 综合线索,给出最终结论。
""",
        expected_output="详细的数据排查报告,包含排查路径、执行的 SQL、关键数据发现和根因分析。",
        agent=agent,
    )


# ==================== 银行核心业务排查系统 Tasks ====================


def create_triage_investigation_task(
    agent,
    issue_description: str,
    system_name: str,
    table_name: str = None,
    data_id: str = None,
    expected_result: str = None,
) -> Task:
    """
    诊断与排查任务 (Task 1)
    由PM Agent执行,负责委派给对应系统专家进行排查
    """
    context_info = []
    if table_name:
        context_info.append(f"涉及表: {table_name}")
    if data_id:
        context_info.append(f"数据ID/批次号: {data_id}")
    if expected_result:
        context_info.append(f"期望结果: {expected_result}")

    context_str = (
        "\n".join([f"- {info}" for info in context_info])
        if context_info
        else "无额外上下文"
    )

    return Task(
        description=f"""分析收到的业务工单并委派给对应的系统研发进行排查。

【工单信息】
- 系统: {system_name}
- 问题描述: {issue_description}
{context_str}

【你的行动指南】
1. **识别系统归属**: 根据 system_name,判断这属于哪个系统:
   - "1104" → 委派给 "1104报送系统专家"
   - "大集中" / "core" → 委派给 "大集中系统资深开发"
   - "EAST" → 委派给 "EAST数据报送工程师"
   - "一表通" / "YBT" → 委派给 "一表通(Unified Reporting)全栈工程师"

2. **委派排查任务** (重要!):
   你 **必须** 使用 "Delegate work to co-worker" 功能,将排查工作指派给对应的系统研发 Agent。
   不要自己尝试回答数据问题,你的职责是协调专家。

3. **指示排查要点**:
   要求被指派的研发 Agent:
   - 使用其专用数据库工具查询 {table_name or "相关表"}
   - 分析具体的数据差异、错误日志或配置问题
   - 找到问题的根本原因 (Root Cause)
   - 提供可落地的修复建议

【期望输出】
你应该等待被指派的研发 Agent 完成排查后,汇总他们提交的技术报告。
报告应包含:
- SQL 查询结果或配置文件内容
- 受影响的数据快照
- 问题的根本原因分析
- 具体的修复步骤
""",
        expected_output="一份包含具体 SQL 查询结果、错误日志分析和技术根因的详细内部报告。",
        agent=agent,
    )


def create_qa_response_task(
    agent, issue_description: str, context: list = None
) -> Task:
    """
    质量验收与回复任务 (Task 2)
    由PM Agent执行,审核技术报告并生成业务友好的回复
    """
    return Task(
        description=f"""审核研发提交的技术报告,并起草给业务人员的正式回复。

【原始问题】
{issue_description}

【你的职责】
1. **质量验收**:
   - 审核上一步中研发提交的技术报告
   - 确认是否包含具体的根因分析(不能是"可能是系统bug"这种模糊表述)
   - 检查是否给出了可落地的修复方案

2. **术语翻译**:
   将技术性的根因翻译成业务能理解的语言:
   - ❌ "字段 accrual_date 存在 NULL 值导致 SUM 聚合函数跳过了3条记录"
   - ✅ "系统在处理提前还款时未正确记录计息日期,导致这3笔贷款未被纳入统计"

   - ❌ "存储过程 SP_EARLY_REPAY v2.3.1 存在逻辑缺陷"
   - ✅ "核心系统的还款处理程序版本较旧,处理部分还款时遗漏了标记更新"

3. **起草回复**:
   生成专业、友好的回复文本,包含:
   - 问题已确认(简要说明是什么问题)
   - 根本原因(业务语言)
   - 下一步动作(已安排修复 / 数据已订正 / 预计修复时间)

【期望输出】
一段给业务人员的正式回复,语言专业但不过度技术化,
让业务人员能够理解问题原因,并知道接下来会如何处理。
""",
        expected_output="给业务人员的最终回复文本,解释了问题原因,并告知已安排修复或数据订正。",
        agent=agent,
        context=context,  # 依赖 Task 1 的输出
    )


# ==================== 统一PM架构 Task ====================


def create_unified_task(user_input: str) -> Task:
    """
    PM的统一任务 (SOTA Plan-and-Solve模式)
    适用于中心化PM架构,由PM接收所有请求并委派给对应系统负责人
    """
    return Task(
        description=f"""你是一个高智商的架构师。在处理用户请求 "{user_input}" 之前，你必须执行以下 Chain of Thought (CoT) 步骤：

1. 【Think】识别主系统与排查优先级。
   - 找出用户请求中明确提到的主系统。
   - **核心准则**: 优先委派给主系统负责人排查。严禁在没有主系统证据的情况下进行“盲目泛化”的全流程排查。

2. 【Plan】制定精准、分步的执行计划。
   - 默认采用单步优先策略：
     - 如果用户只问1104系统，则只安排【1104系统负责人】。
     - 只有当1104专家反馈“证据指向外部系统”时，才在后续步骤扩展涉及范围。

3. 【Delegate】严禁冗余调用。精准指派对应的王牌专家。
   - 遵循“按需申请”原则，不要为了表现全面而呼叫所有同事。

4. 【Synthesize】汇总结果并执行严苛的事实核查(Fact Check)。
   - **Grounding (接地性)**: 每一个结论必须建立在专家返回的证据之上。
   - **禁止猜测**: 专家查不到不代表是其他系统的问题。如果链路中断，请直接报告"排查受限"。
   - 如果主系统排查已闭环，则无需关联其他系统。
""",
        expected_output="包含完整思考过程(Think/Plan)的最终执行报告和对用户的回复",
    )
