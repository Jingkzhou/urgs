"""
并行 SQL 解析模块

该模块提供用于 ProcessPoolExecutor 的 Worker 函数，用于在子进程中解析 SQL 文件。
每个子进程会独立创建 LineageParser 实例，避免进程间共享问题。
"""

from typing import Dict, Any, Tuple, List
import os


def parse_single_file(args: Tuple[str, str, str]) -> Dict[str, Any]:
    """
    解析单个 SQL 文件（Worker 函数，在子进程中执行）
    
    Args:
        args: (file_path, dialect, default_dialect) 元组
              - file_path: SQL 文件路径
              - dialect: 路径自动检测到的方言 (可能为 None)
              - default_dialect: 默认方言
    
    Returns:
        解析结果字典:
        {
            "file_path": str,
            "success": bool,
            "error": str | None,
            "relationships": list,  # 表级别血缘
            "column_dependencies": list  # 列级别血缘
        }
    """
    file_path, detected_dialect, default_dialect = args
    
    result = {
        "file_path": file_path,
        "success": False,
        "error": None,
        "relationships": [],
        "column_dependencies": []
    }
    
    try:
        # 直接导入 LineageParser，避免触发 container.py 中的 Agent 初始化
        from parsers.sql_parser import LineageParser
        
        dialect = detected_dialect if detected_dialect else default_dialect
        parser = LineageParser(dialect=dialect)
        
        # 读取 SQL 文件
        with open(file_path, 'r', encoding='utf-8') as f:
            sql_content = f.read()
        
        # 解析表级别血缘
        parse_result = parser.parse(sql_content, source_file=file_path)
        
        # 解析列级别血缘
        col_dependencies = parser.get_column_lineage(sql_content, source_file=file_path)
        
        result["success"] = True
        result["relationships"] = parse_result.get("relationships", [])
        result["column_dependencies"] = col_dependencies
        
        # 如果没有 relationships，尝试从 sources/targets 构建
        if not result["relationships"] and "sources" in parse_result and "targets" in parse_result:
            for source in parse_result.get("sources", []):
                for target in parse_result.get("targets", []):
                    result["relationships"].append({
                        "source": source,
                        "target": target,
                        "type": "fdd"
                    })
        
    except Exception as e:
        result["error"] = str(e)
    
    return result


def detect_dialect_from_path(file_path: str) -> str | None:
    """
    根据文件路径自动检测 SQL 方言
    
    Args:
        file_path: SQL 文件路径
    
    Returns:
        检测到的方言，或 None
    """
    path_parts = file_path.lower().split(os.sep)
    
    supported_dialects = {
        'hive': 'hive',
        'oracle': 'oracle',
        'mysql': 'mysql',
        'postgresql': 'postgresql',
        'postgres': 'postgresql',
        'sqlserver': 't-sql'
    }
    
    for part in path_parts:
        if part in supported_dialects:
            return supported_dialects[part]
    
    return None


def prepare_file_tasks(sql_files: List[str], default_dialect: str) -> List[Tuple[str, str, str]]:
    """
    准备并行任务参数
    
    Args:
        sql_files: SQL 文件路径列表
        default_dialect: 默认方言
    
    Returns:
        任务参数列表 [(file_path, detected_dialect, default_dialect), ...]
    """
    tasks = []
    for file_path in sql_files:
        detected = detect_dialect_from_path(file_path)
        tasks.append((file_path, detected, default_dialect))
    return tasks
