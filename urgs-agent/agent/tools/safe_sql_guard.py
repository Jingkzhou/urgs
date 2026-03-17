# 安全SQL执行工具 (带安全护栏)
# 防止危险操作: DROP, DELETE, UPDATE, TRUNCATE等

from crewai.tools import BaseTool
from typing import Type
from pydantic import BaseModel, Field
import re


class SafeSQLInput(BaseModel):
    """安全SQL执行输入"""

    query: str = Field(..., description="要执行的SQL查询语句")


class SafeSQLTool(BaseTool):
    """
    安全的SQL执行工具 (只读,带安全护栏)

    安全检查:
    1. 禁止 DROP/DELETE/UPDATE/INSERT/TRUNCATE 等修改操作
    2. 检查是否有WHERE条件(避免全表扫描)
    3. 限制返回结果数量
    """

    name: str = "safe_sql_executor"
    description: str = (
        "安全的SQL查询工具,仅支持SELECT查询。"
        "自动拒绝DROP/DELETE/UPDATE等修改操作,并检查查询性能。"
        "适用于数据查询和分析场景。"
    )
    args_schema: Type[BaseModel] = SafeSQLInput

    def _run(self, query: str) -> str:
        """执行带安全检查的SQL查询"""

        # 1. 安全检查: 禁止修改操作
        dangerous_keywords = [
            "DROP",
            "DELETE",
            "UPDATE",
            "INSERT",
            "TRUNCATE",
            "ALTER",
            "CREATE",
            "GRANT",
            "REVOKE",
        ]

        query_upper = query.upper()
        for keyword in dangerous_keywords:
            if re.search(rf"\b{keyword}\b", query_upper):
                return f"""❌ 安全拒绝: 检测到危险操作 '{keyword}'

这是一个只读系统,禁止执行修改操作。

允许的操作:
- SELECT: 查询数据
- SHOW: 查看表结构
- DESCRIBE: 查看表定义

如需修改数据,请联系DBA或使用专门的数据变更流程。
"""

        # 2. 性能检查: SELECT语句应有WHERE条件
        if "SELECT" in query_upper:
            # 检查是否有WHERE条件(排除聚合查询如COUNT(*))
            has_where = "WHERE" in query_upper
            has_limit = "LIMIT" in query_upper
            is_aggregate = any(
                agg in query_upper
                for agg in ["COUNT(*)", "SUM(", "AVG(", "MAX(", "MIN("]
            )

            if not has_where and not has_limit and not is_aggregate:
                return f"""⚠️ 性能警告: 缺少WHERE或LIMIT条件

SQL: {query}

警告原因:
- 该查询可能导致全表扫描
- 返回大量数据会影响性能

建议:
- 添加WHERE条件过滤数据
- 或者添加LIMIT限制返回行数 (如 LIMIT 100)

是否继续执行? 请明确添加LIMIT后重新提交。
"""

        # 3. TODO: 实际SQL执行(这里使用Mock实现)
        # 在生产环境中,这里应该连接真实数据库并执行查询
        return self._mock_execute(query)

    def _mock_execute(self, query: str) -> str:
        """
        Mock SQL执行(示例)
        生产环境替换为真实的数据库连接
        """
        return f"""✅ SQL查询通过安全检查

执行的SQL: {query}

【Mock结果 - 生产环境需替换为真实DB查询】
返回前5行数据:
  Row 1: id=1, value=100
  Row 2: id=2, value=200
  Row 3: id=3, value=300
  ...

总计: 查询返回 X 行数据
执行时间: 0.05s

⚠️ 注意: 当前为Mock实现,请在生产环境中连接真实数据库。
"""


def get_safe_sql_tool():
    """获取安全SQL工具"""
    return SafeSQLTool()
