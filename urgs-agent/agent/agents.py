# CrewAI Agent 定义
# URGS 智能助手 Agent 角色

from crewai import Agent, LLM
from core.config import get_settings


def get_llm() -> LLM:
    """获取配置的 LLM 实例"""
    settings = get_settings()
    return LLM(
        model=f"openai/{settings.model_name}",
        base_url=settings.openai_base_url,
        api_key=settings.openai_api_key,
    )


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
        llm=get_llm(),
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
        llm=get_llm(),
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
        llm=get_llm(),
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
        llm=get_llm(),
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
当用户询问“有多少任务”、“状态分布如何”等统计类或明细类问题时，你会：
1. 理解用户意图
2. 生成正确的 SQL 语句（基于 MySQL 语法）
3. 执行查询并获取结果
4. 根据结果回答用户问题

你非常谨慎，只执行查询（SELECT）操作，绝不修改数据。""",
        verbose=True,
        allow_delegation=False,
        llm=get_llm(),
        tools=tools or [],
    )
