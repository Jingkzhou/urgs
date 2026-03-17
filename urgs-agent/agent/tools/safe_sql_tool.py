from crewai.tools import tool
from core.config import get_settings
from core.logging import get_logger
import pymysql
import re

logger = get_logger("tools.sql")
settings = get_settings()


@tool("安全SQL执行器")
def execute_safe_sql(sql: str) -> str:
    """
    安全执行 SQL 查询并返回结果。
    只能执行 SELECT 语句。严禁执行 INSERT, UPDATE, DELETE, DROP 等修改操作。

    Args:
        sql: 要执行的 SQL 查询语句

    Returns:
        JSON 格式的查询结果列表，或错误信息。
    """
    # 1. 安全检查：拦截写操作
    forbidden_keywords = [
        r"\bINSERT\b",
        r"\bUPDATE\b",
        r"\bDELETE\b",
        r"\bDROP\b",
        r"\bTRUNCATE\b",
        r"\bALTER\b",
        r"\bCREATE\b",
        r"\bGRANT\b",
    ]

    # 移除注释以防止绕过检测
    clean_sql = re.sub(r"/\*.*?\*/", "", sql, flags=re.DOTALL)
    clean_sql = re.sub(r"--.*", "", clean_sql)
    clean_sql_upper = clean_sql.upper()

    for pattern in forbidden_keywords:
        if re.search(pattern, clean_sql_upper):
            # 允许 CREATE TEMPORARY TABLE (可选，如果业务需要)
            # 但这里作为数据取证员，严格只读更安全
            logger.warning("unsafe_sql_blocked", sql=sql)
            return f"❌ 安全拦截：检测到可能的写操作关键字 ({pattern})。本工具只允许执行 SELECT 查询。"

    if not clean_sql_upper.strip().startswith(
        "SELECT"
    ) and not clean_sql_upper.strip().startswith("SHOW"):
        return "❌ 安全拦截：语句必须以 SELECT 或 SHOW 开头。"

    # 2. 执行查询
    try:
        conn = pymysql.connect(
            host=settings.db_host,
            port=settings.db_port,
            user=settings.db_user,
            password=settings.db_password,
            database=settings.db_name,
            charset="utf8mb4",
            cursorclass=pymysql.cursors.DictCursor,
        )

        with conn.cursor() as cursor:
            # 2.1 强制 Limit 保护
            limit_pattern = r"\bLIMIT\s+\d+"
            warning_msg = ""

            # 如果没有 LIMIT，且不是 SHOW 命令，强制添加 LIMIT 20
            if not re.search(
                limit_pattern, clean_sql_upper
            ) and not clean_sql_upper.strip().startswith("SHOW"):
                # 简单粗暴处理：移除结尾的分号，添加 LIMIT
                sql = re.sub(r";\s*$", "", sql) + " LIMIT 20"
                warning_msg = " (⚠️ 为了安全，系统已自动添加 LIMIT 20)"

            cursor.execute(sql)
            rows = cursor.fetchall()

            # 2.2 结果截断保护 (Token 保护)
            import json

            try:
                result_json = json.dumps(
                    rows, default=str, ensure_ascii=False, indent=2
                )
            except Exception:
                result_json = str(rows)

            MAX_CHARS = 5000
            if len(result_json) > MAX_CHARS:
                result_json = result_json[:MAX_CHARS] + "\n... (结果过长已截断)"
                warning_msg += " (⚠️ 结果字符数过多，已截断)"

            # 行数提示
            row_count_info = f"共 {len(rows)} 行"
            if (
                "LIMIT" in clean_sql_upper and len(rows) >= 20
            ):  # 只是猜测可能触发了 limit
                pass

            return f"✅ 执行成功 ({row_count_info}){warning_msg}:\n{result_json}"

    except Exception as e:
        logger.error("sql_execution_failed", error=str(e), sql=sql)
        return f"🚨 SQL 执行出错: {str(e)}"
    finally:
        if "conn" in locals() and conn.open:
            conn.close()
