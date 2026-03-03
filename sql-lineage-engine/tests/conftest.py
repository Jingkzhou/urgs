"""
黄金测试集 pytest 配置文件

功能：
1. 将项目根目录加入 sys.path
2. 提供 LineageParser 的 fixtures
3. Mock MetadataResolver 的 API 调用（测试不依赖外部服务）
"""
import sys
import os
import pytest
from unittest.mock import patch, MagicMock

# 将项目根目录加入 path
PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
if PROJECT_ROOT not in sys.path:
    sys.path.insert(0, PROJECT_ROOT)


@pytest.fixture
def mock_metadata_resolver():
    """
    Mock MetadataResolver，避免测试依赖外部 API。
    返回的 resolver 对所有表返回 None（无元数据），
    但不会报错阻断流程。
    """
    with patch("utils.metadata_resolver.MetadataResolver.get_table_metadata", return_value=None):
        with patch("utils.metadata_resolver.MetadataResolver.validate_column", return_value={
            "exists": None, "confidence": "MEDIUM", "note": "Mocked for testing"
        }):
            with patch("utils.metadata_resolver.MetadataResolver.get_table_fields", return_value=[]):
                yield


@pytest.fixture
def lineage_parser_oracle(mock_metadata_resolver):
    """Oracle 方言的 LineageParser 实例"""
    from parsers.sql_parser import LineageParser
    return LineageParser(dialect="oracle")


@pytest.fixture
def lineage_parser_mysql(mock_metadata_resolver):
    """MySQL 方言的 LineageParser 实例"""
    from parsers.sql_parser import LineageParser
    return LineageParser(dialect="mysql")


@pytest.fixture
def lineage_parser_hive(mock_metadata_resolver):
    """Hive 方言的 LineageParser 实例"""
    from parsers.sql_parser import LineageParser
    return LineageParser(dialect="hive")
