from crewai.tools import tool
from core.config import get_settings
from core.logging import get_logger
import pymysql

logger = get_logger("tools.schema")
settings = get_settings()


@tool("查询数据库表结构")
def lookup_schema(table_name_hint: str) -> str:
    """
    查询数据库表结构。
    输入：表名关键词（如 user, order, sys_user）
    输出：匹配表的字段定义、类型、键信息（DDL摘要）
    """
    if not table_name_hint or len(table_name_hint) < 2:
        return "请提供更具体的表名关键词（至少2个字符）"

    try:
        conn = pymysql.connect(
            host=settings.db_host,
            port=settings.db_port,
            user=settings.db_user,
            password=settings.db_password,
            database=settings.db_name,
            charset="utf8mb4",
        )

        output = []
        with conn.cursor() as cursor:
            # 1. 查找匹配的表
            cursor.execute(
                "SELECT table_name, table_comment FROM information_schema.tables "
                "WHERE table_schema = %s AND table_name LIKE %s LIMIT 5",
                (settings.db_name, f"%{table_name_hint}%"),
            )
            tables = cursor.fetchall()

            if not tables:
                return f"未找到包含 '{table_name_hint}' 的表。"

            for table in tables:
                table_name = table[0]
                table_comment = table[1] or ""
                output.append(f"📦 TABLE: {table_name} ({table_comment})")

                # 2. 获取列信息
                cursor.execute(
                    "SELECT column_name, column_type, column_key, column_comment, is_nullable, extra "
                    "FROM information_schema.columns "
                    "WHERE table_schema = %s AND table_name = %s "
                    "ORDER BY ordinal_position",
                    (settings.db_name, table_name),
                )
                columns = cursor.fetchall()

                output.append("  Columns:")
                for col in columns:
                    name, type_, key, comment, nullable, extra = col
                    key_str = f"[{key}]" if key else ""
                    null_str = "NULL" if nullable == "YES" else "NOT NULL"
                    comment_str = f"// {comment}" if comment else ""

                    output.append(
                        f"    - {name} ({type_}) {key_str} {null_str} {extra} {comment_str}"
                    )
                output.append("")

        conn.close()
        return "\n".join(output)

    except Exception as e:
        logger.error("schema_lookup_failed", error=str(e))
        return f"查询表结构失败: {str(e)}"
