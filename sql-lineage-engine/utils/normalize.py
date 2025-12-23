"""
表名标准化工具模块

用于统一 GSP 和 sqlglot 解析器输出的表名格式
"""


def normalize_table_name(name: str) -> str:
    """
    标准化表名，将 GSP 错误拆分的表名还原为正确格式
    
    处理场景：
    1. `G12_11`.``.`B` -> G12_11..B  (GSP 错误拆分)
    2. `schema`.`table` -> schema.table  (正常带引号)
    3. G12_11..B -> G12_11..B  (已正确，保持不变)
    4. SMTMODS_L_ACCT_LOAN -> SMTMODS_L_ACCT_LOAN  (普通表名不变)
    
    Args:
        name: 原始表名
        
    Returns:
        标准化后的表名
    """
    if not name:
        return name
    
    # 移除反引号
    clean = name.replace('`', '')
    
    # 如果没有反引号，直接返回（已经是标准格式或普通表名）
    if clean == name:
        return name
    
    # 按 . 分割
    parts = clean.split('.')
    
    # 重组：处理空部分（代表原始的 ..）
    result = []
    for p in parts:
        if p:
            result.append(p)
        elif result:  # 空部分且前面有内容，说明是 ..
            result[-1] += '.'  # 追加点号到前一个部分
    
    return '.'.join(result) if result else name
