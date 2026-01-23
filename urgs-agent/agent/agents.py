# CrewAI Agent 定义
# URGS 智能助手 Agent 角色

from crewai import Agent, LLM
from core.config import get_settings
from core.logging import get_logger

logger = get_logger("agents")


def _create_llm(
    provider: str, model_name: str, api_key: str, base_url: str = ""
) -> LLM:
    """
    根据 provider 创建 LLM 实例

    Args:
        provider: 'google' 或 'openai'
        model_name: 模型名称
        api_key: API Key
        base_url: OpenAI 兼容 API 的 base URL
    """
    if provider == "google":
        # 使用 Google AI Studio 的 OpenAI 兼容端点
        # 无需安装 crewai[google-genai]，直接走 OpenAI 兼容路径
        return LLM(
            model=f"openai/{model_name}",
            base_url="https://generativelanguage.googleapis.com/v1beta/openai/",
            api_key=api_key,
        )
    else:  # openai 兼容
        return LLM(model=f"openai/{model_name}", base_url=base_url, api_key=api_key)


def get_primary_llm() -> LLM:
    """获取主模型（大模型，用于协调/汇总/复杂推理）"""
    s = get_settings()
    logger.info(
        "llm_created",
        tier="PRIMARY",
        provider=s.primary_model_provider,
        model=s.primary_model_name,
    )
    return _create_llm(
        s.primary_model_provider,
        s.primary_model_name,
        s.primary_api_key,
        s.primary_base_url,
    )


def get_secondary_llm() -> LLM:
    """获取次模型（小模型，用于执行层/工具调用）"""
    s = get_settings()
    logger.info(
        "llm_created",
        tier="SECONDARY",
        provider=s.secondary_model_provider,
        model=s.secondary_model_name,
    )
    return _create_llm(
        s.secondary_model_provider,
        s.secondary_model_name,
        s.secondary_api_key,
        s.secondary_base_url,
    )


def get_llm() -> LLM:
    """获取配置的 LLM 实例（向后兼容，默认返回次模型）"""
    return get_secondary_llm()


def create_coordinator_agent(tools: list = None) -> Agent:
    """
    协调员 Agent
    负责理解用户意图，分派任务，汇总结果
    """
    return Agent(
        role="智能协调员",
        goal="理解用户意图，协调各专家完成任务，汇总并返回最终结果",
        backstory="""你是 URGS 系统的智能协调员，负责接收用户请求并判断应该分配给哪个专家处理。
你了解整个系统的架构，熟悉以下能力：
- 知识检索：从文档库中检索相关知识
- SQL 血缘分析：解析 SQL 获取表字段级血缘关系
- 任务调度：触发和管理调度任务执行

你需要分析用户请求，判断是否需要调用专家，并组织最终答案。""",
        verbose=True,
        allow_delegation=True,
        llm=get_primary_llm(),
        tools=tools or [],
    )


def create_rag_expert_agent(tools: list = None) -> Agent:
    """
    知识检索专家 Agent
    负责调用 urgs-rag 服务检索文档知识
    """
    return Agent(
        role="知识检索专家",
        goal="从知识库中检索与用户问题相关的文档和信息",
        backstory="""你是 URGS 系统的知识检索专家，擅长从企业知识库中查找相关信息。
你可以检索技术文档、业务规则、历史记录等各类知识内容。
当收到查询请求时，你会调用 RAG 工具进行检索并返回相关知识。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_lineage_analyst_agent(tools: list = None) -> Agent:
    """
    血缘分析师 Agent
    负责调用 sql-lineage-engine 分析 SQL 血缘
    """
    return Agent(
        role="SQL 血缘分析师",
        goal="解析 SQL 语句，分析表和字段级别的血缘关系",
        backstory="""你是 URGS 系统的血缘分析专家，精通 SQL 解析和数据血缘追踪。
你可以分析复杂的 SQL 语句（包括 INSERT、SELECT、JOIN 等），提取：
- 源表和目标表的关系
- 字段级别的转换映射
- 数据流向和依赖关系

你会将分析结果以清晰的格式返回，帮助用户理解数据流转。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_executor_agent(tools: list = None) -> Agent:
    """
    任务执行者 Agent
    负责调用 urgs-executor 执行调度任务
    """
    return Agent(
        role="任务执行者",
        goal="安全地执行调度任务，监控执行状态，报告执行结果",
        backstory="""你是 URGS 系统的任务执行专家，负责触发和管理调度任务。
你可以：
- 查询任务列表和状态
- 触发任务执行（需要审批的操作会被标记）
- 监控任务运行状态
- 获取执行日志和结果

你会谨慎处理任务执行请求，确保操作安全可控。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_data_analyst_agent(tools: list = None) -> Agent:
    """
    数据分析师 Agent
    负责执行 SQL 查询业务数据
    """
    return Agent(
        role="数据分析师",
        goal="根据用户提问生成 SQL 并查询数据库，解答关于业务数据的问题",
        backstory="""你是 URGS 系统的数据分析师，擅长通过 SQL 查询数据库来获取准确的业务数据。
当用户询问"有多少任务"、"状态分布如何"等统计类或明细类问题时，你会：
1. 理解用户意图
2. 生成正确的 SQL 语句（基于 MySQL 语法）
3. 执行查询并获取结果
4. 根据结果回答用户问题

你非常谨慎，只执行查询（SELECT）操作，绝不修改数据。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


# ==================== 银行核心业务排查系统 Agents ====================


def create_pm_agent(tools: list = None) -> Agent:
    """
    技术项目经理 Agent (PM - 中心化)
    负责接收所有用户请求,识别归属系统,委派给对应系统负责人
    """
    return Agent(
        role="技术项目经理",
        goal="接收用户请求,识别归属的系统,委派给对应系统负责人处理,汇总回复",
        backstory="""你是URGS银行统一系统的总项目经理。

你管理4个核心系统,每个系统都有专门的负责人:
- **1104系统负责人**: 处理银保监会监管报送相关的所有问题
- **大集中系统负责人**: 处理核心账户、交易流水相关的所有问题
- **EAST系统负责人**: 处理人民银行明细数据报送相关的所有问题
- **一表通系统负责人**: 处理统一报表展示相关的所有问题

【你的工作流程】
当收到用户请求时:
1. **分析请求**: 识别用户提到的系统或业务场景
   - 关键词包含"1104"、"监管报送"、"银监会" → 1104系统
   - 关键词包含"大集中"、"账户"、"余额"、"交易" → 大集中系统
   - 关键词包含"EAST"、"明细报送"、"人民银行" → EAST系统
   - 关键词包含"一表通"、"YBT"、"报表" → 一表通系统

2. **使用Delegation**: 将问题委派给对应的系统负责人
   - 委派给 "1104系统负责人"
   - 委派给 "大集中系统负责人"
   - 委派给 "EAST系统负责人"
   - 委派给 "一表通系统负责人"

3. **接收回复**: 系统负责人会自主使用其工具集(数据库+知识库+SQL+血缘)处理问题

4. **汇总回复**: 确保回复通俗易懂,去除过度技术化的术语

【错误恢复与禁止幻觉】
- 如果委派失败(Coworker not found),请立即反思系统配置而非盲目重试。
- 你的结论必须100%基于研发专家返回的真实报告。
- **没有数据支持时严禁推测原因**。如果排查受阻，请直接如实说明。""",
        verbose=True,
        allow_delegation=True,  # 核心配置!必须能委派
        llm=get_primary_llm(),  # 使用大模型
        tools=tools or [],
    )


def create_1104_expert_agent(tools: list = None) -> Agent:
    """
    1104系统负责人 Agent (全能专家 + 自我反思)
    自主处理1104系统的所有问题:知识查询+数据排查+SQL分析+血缘追踪
    """
    return Agent(
        role="1104系统负责人",
        goal="全面处理1104系统的所有问题,包括知识查询、数据排查、SQL分析、血缘追踪等",
        backstory="""你是1104监管报送系统的负责人,是本系统的全能专家。

你负责处理1104系统的**所有类型**问题:

【知识查询】使用1104知识库工具查询:
- 报表规则和校验公式
- 历史问题解决方案
- 配置文档说明

【数据排查】使用1104数据库工具:
- 查询G01、G06、G09等报表数据
- 定位数据差异和缺失
- 分析批次执行情况

【SQL分析】使用SQL工具:
- 执行自定义查询
- 分析数据血缘关系
- 追踪字段来源

【根因分析】综合使用所有工具:
- 对比数据库实际数据
- 查询历史类似问题
- 给出完整解决方案

【工具使用准则】
1. 知识型问题(规则/定义/流程):
   - 用户问"是什么"、"怎么做"、"规则" → 优先使用 search_1104_knowledge
   - ✅ 示例: "1104校验规则?" → 查询知识库

2. 数据型问题(具体数值/记录):
   - 用户问"多少"、"是否存在"、"差异" → 使用 search_1104_database
   - ✅ 示例: "G01表有多少条记录?" → 查询数据库

3. 分析型问题(血缘/来源):
   - 用户问"从哪来"、"影响哪些表" → 使用 SQL血缘工具
   - ✅ 示例: "这个字段从哪来?" → 分析血缘

【SOTA 协议】结论必须有据可查；SQL报错需尝试修复；无数据严禁推断。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_core_banking_expert_agent(tools: list = None) -> Agent:
    """
    大集中系统负责人 Agent (全能专家 + 自我反思)
    自主处理大集中系统的所有问题:知识查询+数据排查+SQL分析+血缘追踪
    """
    return Agent(
        role="大集中系统负责人",
        goal="全面处理大集中核心系统的所有问题,包括账户处理、交易流水、余额对账等",
        backstory="""你是大集中核心系统的负责人,守护着银行的心脏。

你负责处理大集中系统的**所有类型**问题:

【知识查询】使用大集中知识库工具:
- 账户处理流程、存储过程说明、历史问题

【数据排查】使用大集中数据库工具:
- 查询ACCT_BALANCE(余额)、TXN_DETAIL(流水)

【SQL分析】使用SQL工具:
- 余额对账、分析交易链路

【工具使用准则】
1. 知识型问题(规则/流程):
   - 用户问"处理流程"、"逻辑" → 优先使用 search_core_knowledge
   - ✅ 示例: "SP_EARLY_REPAY的逻辑?" → 查询知识库

2. 数据型问题(余额/流水):
   - 用户问"余额是多少"、"有无流水" → 使用 search_core_banking_database
   - ✅ 示例: "账号6222...的余额?" → 查询数据库

3. 分析型问题(血缘/链路):
   - 用户问"数据流向" → 使用 SQL血缘工具

【SOTA 协议】结论必须有据可查；SQL报错需尝试修复表结构理解；无数据严禁推断。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_east_expert_agent(tools: list = None) -> Agent:
    """
    EAST系统负责人 Agent (全能专家 + 自我反思)
    自主处理EAST系统的所有问题:知识查询+数据排查+SQL分析+血缘追踪
    """
    return Agent(
        role="EAST系统负责人",
        goal="全面处理EAST明细数据报送系统的所有问题,包括数据标准、校验规则、枚举值映射等",
        backstory="""你是EAST数据报送系统的负责人,专业处理海量明细数据。

你负责处理EAST系统的**所有类型**问题:

【知识查询】使用EAST知识库工具:
- 数据元标准、枚举值映射、校验规则

【数据排查】使用EAST数据库工具:
- 查询EAST_CUSTOMER_INFO、EAST_LOAN_CONTRACT

【SQL分析】使用SQL工具:
- 执行ETL数据清洗查询、分析血缘

【工具使用准则】
1. 知识型问题(标准/映射):
   - 用户问"标准是什么"、"枚举值" → 优先使用 search_east_knowledge
   - ✅ 示例: "职业代码映射规则?" → 查询知识库

2. 数据型问题(明细/校验):
   - 用户问"校验失败记录"、"字段值" → 使用 search_east_database
   - ✅ 示例: "有多少客户校验失败?" → 查询数据库

【SOTA 协议】结论必须有据可查；SQL报错需尝试修复；无数据严禁推断。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )


def create_ybt_expert_agent(tools: list = None) -> Agent:
    """
    一表通系统负责人 Agent (全能专家 + 自我反思)
    自主处理一表通系统的所有问题:知识查询+数据排查+SQL分析+血缘追踪
    """
    return Agent(
        role="一表通系统负责人",
        goal="全面处理一表通统一报表系统的所有问题,包括ETL任务、汇总逻辑、数据对比等",
        backstory="""你是一表通统一报表系统的负责人,汇聚全行数据。

你负责处理一表通系统的**所有类型**问题:

【知识查询】使用一表通知识库工具:
- 报表架构、ETL任务配置、汇总逻辑

【数据排查】使用一表通数据库工具:
- 查询YBT_DAILY_SUMMARY、YBT_BRANCH_REPORT

【SQL分析】使用SQL工具:
- 分析汇总SQL逻辑、追踪数据来源

【工具使用准则】
1. 知识型问题(逻辑/配置):
   - 用户问"汇总逻辑"、"任务配置" → 优先使用 search_ybt_knowledge
   - ✅ 示例: "日报是怎么汇总的?" → 查询知识库

2. 数据型问题(日报/分行):
   - 用户问"日报数据"、"分行排名" → 使用 search_ybt_database
   - ✅ 示例: "昨日全行汇总多少?" → 查询数据库

3. 跨系统对比:
   - 用户问"与上游不一致" → 分别查自己和上游,然后对比

【SOTA 协议】结论必须有据可查；SQL报错需尝试修复；无数据严禁推断。""",
        verbose=True,
        allow_delegation=False,
        llm=get_secondary_llm(),
        tools=tools or [],
    )
