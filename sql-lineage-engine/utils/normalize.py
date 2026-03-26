"""
表名标准化工具模块

用于统一 GSP 和 sqlglot 解析器输出的表名格式
"""


def normalize_table_name(name: str) -> str:
    """
    标准化表名，去除引号并过滤空 part。

    处理场景：
    - `schema`.`table`   → schema.table
    - `G12_11`.``.`B`    → G12_11.B
    - schema.table       → schema.table（不变）
    - plain_table        → plain_table（不变）

    Args:
        name: 原始表名

    Returns:
        标准化后的表名
    """
    if not name:
        return name

    # 去除所有引号（反引号、双引号）
    clean = name.replace('`', '').replace('"', '').strip()

    # 如果去除引号后与原始相同（普通表名），直接返回
    if clean == name:
        return name

    # 过滤空 part，重新组装
    parts = [p.strip() for p in clean.split('.') if p.strip()]
    return '.'.join(parts) if parts else name
