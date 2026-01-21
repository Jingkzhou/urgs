# CrewAI 工具定义
# URGS 系统工具层

from typing import Optional
import httpx
from crewai.tools import tool
from core.config import get_settings
from core.logging import get_logger

logger = get_logger("tools")


# ==================== RAG 知识检索工具 ====================


@tool("RAG知识检索")
def query_knowledge(question: str) -> str:
    """
    从 URGS 知识库中检索相关信息。

    Args:
        question: 用户的问题或查询关键词

    Returns:
        检索到的相关知识内容
    """
    settings = get_settings()
    rag_url = getattr(settings, "rag_service_url", "http://localhost:8001")

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                f"{rag_url}/api/rag/query", json={"question": question}
            )
            response.raise_for_status()
            result = response.json()
            return result.get("answer", "未找到相关信息")
    except httpx.HTTPError as e:
        logger.warning("rag_query_failed", error=str(e))
        return f"知识检索失败: {str(e)}"


@tool("文档摘要检索")
def search_documents(keywords: str, top_k: int = 5) -> str:
    """
    根据关键词搜索相关文档。

    Args:
        keywords: 搜索关键词
        top_k: 返回结果数量，默认5条

    Returns:
        匹配的文档列表摘要
    """
    settings = get_settings()
    rag_url = getattr(settings, "rag_service_url", "http://localhost:8001")

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.post(
                f"{rag_url}/api/rag/search", json={"keywords": keywords, "top_k": top_k}
            )
            response.raise_for_status()
            result = response.json()
            docs = result.get("documents", [])
            if not docs:
                return "未找到匹配的文档"
            return "\n".join(
                [
                    f"- {doc.get('title', '无标题')}: {doc.get('summary', '')}"
                    for doc in docs
                ]
            )
    except httpx.HTTPError as e:
        logger.warning("doc_search_failed", error=str(e))
        return f"文档搜索失败: {str(e)}"


# ==================== SQL 血缘分析工具 ====================


@tool("SQL血缘分析")
def analyze_sql_lineage(sql: str, dialect: str = "mysql") -> str:
    """
    解析 SQL 语句，分析表和字段级别的血缘关系。

    Args:
        sql: 要分析的 SQL 语句
        dialect: SQL 方言，支持 mysql, postgresql, hive 等

    Returns:
        血缘分析结果，包含源表、目标表、字段映射
    """
    settings = get_settings()
    lineage_url = getattr(settings, "lineage_service_url", "http://localhost:8002")

    try:
        with httpx.Client(timeout=60.0) as client:
            response = client.post(
                f"{lineage_url}/api/lineage/parse",
                json={"sql": sql, "dialect": dialect},
            )
            response.raise_for_status()
            result = response.json()

            # 格式化血缘结果
            lineage = result.get("lineage", {})
            sources = lineage.get("sources", [])
            targets = lineage.get("targets", [])

            output = []
            output.append(f"**源表**: {', '.join(sources) if sources else '无'}")
            output.append(f"**目标表**: {', '.join(targets) if targets else '无'}")

            if "columns" in lineage:
                output.append("\n**字段血缘**:")
                for col in lineage["columns"]:
                    output.append(
                        f"  - {col.get('source', '?')} → {col.get('target', '?')}"
                    )

            return "\n".join(output)
    except httpx.HTTPError as e:
        logger.warning("lineage_analysis_failed", error=str(e))
        return f"血缘分析失败: {str(e)}"


@tool("查询表血缘关系")
def query_table_lineage(table_name: str, direction: str = "both") -> str:
    """
    查询指定表的血缘关系（上下游）。

    Args:
        table_name: 表名
        direction: 查询方向，upstream(上游)、downstream(下游)、both(双向)

    Returns:
        表的血缘关系图
    """
    settings = get_settings()
    api_url = getattr(settings, "api_service_url", "http://localhost:8080")

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.get(
                f"{api_url}/api/lineage/table/{table_name}",
                params={"direction": direction},
            )
            response.raise_for_status()
            result = response.json()

            upstream = result.get("upstream", [])
            downstream = result.get("downstream", [])

            output = [f"**表 {table_name} 的血缘关系**"]
            if upstream:
                output.append(f"\n上游表: {', '.join(upstream)}")
            if downstream:
                output.append(f"\n下游表: {', '.join(downstream)}")
            if not upstream and not downstream:
                output.append("\n未发现血缘关系")

            return "\n".join(output)
    except httpx.HTTPError as e:
        logger.warning("table_lineage_query_failed", error=str(e))
        return f"血缘查询失败: {str(e)}"


# ==================== 任务执行工具 ====================


@tool("查询任务列表")
def list_jobs(status: Optional[str] = None, limit: int = 10) -> str:
    """
    查询调度任务列表。

    Args:
        status: 任务状态过滤，可选值：running, success, failed, pending
        limit: 返回数量限制

    Returns:
        任务列表信息
    """
    settings = get_settings()
    api_url = getattr(settings, "api_service_url", "http://localhost:8080")

    try:
        params = {"limit": limit}
        if status:
            params["status"] = status

        with httpx.Client(timeout=30.0) as client:
            response = client.get(f"{api_url}/api/jobs", params=params)
            response.raise_for_status()
            result = response.json()

            jobs = result.get("data", [])
            if not jobs:
                return "当前没有任务"

            output = ["**调度任务列表**\n"]
            for job in jobs[:limit]:
                status_icon = {
                    "running": "🔄",
                    "success": "✅",
                    "failed": "❌",
                    "pending": "⏳",
                }.get(job.get("status", ""), "❓")
                output.append(
                    f"{status_icon} [{job.get('id')}] {job.get('name', '未命名')} - {job.get('status', '未知')}"
                )

            return "\n".join(output)
    except httpx.HTTPError as e:
        logger.warning("list_jobs_failed", error=str(e))
        return f"查询任务失败: {str(e)}"


@tool("查询任务详情")
def get_job_detail(job_id: str) -> str:
    """
    获取指定任务的详细信息。

    Args:
        job_id: 任务 ID

    Returns:
        任务详情，包含配置、执行历史等
    """
    settings = get_settings()
    api_url = getattr(settings, "api_service_url", "http://localhost:8080")

    try:
        with httpx.Client(timeout=30.0) as client:
            response = client.get(f"{api_url}/api/jobs/{job_id}")
            response.raise_for_status()
            job = response.json().get("data", {})

            output = [
                f"**任务详情: {job.get('name', job_id)}**\n",
                f"- ID: {job.get('id')}",
                f"- 状态: {job.get('status')}",
                f"- 类型: {job.get('type', '未知')}",
                f"- Cron: {job.get('cron', '无')}",
                f"- 最后执行: {job.get('lastRunTime', '从未执行')}",
            ]

            return "\n".join(output)
    except httpx.HTTPError as e:
        logger.warning("get_job_detail_failed", error=str(e))
        return f"获取任务详情失败: {str(e)}"


@tool("触发任务执行")
def trigger_job(job_id: str, params: Optional[str] = None) -> str:
    """
    触发指定任务执行。此操作需要审批确认。

    Args:
        job_id: 要执行的任务 ID
        params: 可选的执行参数 (JSON 格式)

    Returns:
        执行触发结果

    注意: 这是一个写操作，系统可能会要求审批确认。
    """
    settings = get_settings()
    api_url = getattr(settings, "api_service_url", "http://localhost:8080")

    try:
        import json

        body = {"jobId": job_id}
        if params:
            try:
                body["params"] = json.loads(params)
            except json.JSONDecodeError:
                body["params"] = params

        with httpx.Client(timeout=30.0) as client:
            response = client.post(f"{api_url}/api/jobs/{job_id}/trigger", json=body)
            response.raise_for_status()
            result = response.json()

            return f"✅ 任务 {job_id} 已触发执行，执行ID: {result.get('executionId', '未知')}"
    except httpx.HTTPError as e:
        logger.warning("trigger_job_failed", error=str(e))
        return f"触发任务失败: {str(e)}"


# ==================== 工具集合 ====================


def get_rag_tools() -> list:
    """获取 RAG 相关工具"""
    return [query_knowledge, search_documents]


def get_lineage_tools() -> list:
    """获取血缘分析相关工具"""
    return [analyze_sql_lineage, query_table_lineage]


def get_executor_tools() -> list:
    """获取任务执行相关工具"""
    return [list_jobs, get_job_detail, trigger_job]


def get_all_tools() -> list:
    """获取所有工具"""
    return get_rag_tools() + get_lineage_tools() + get_executor_tools()
