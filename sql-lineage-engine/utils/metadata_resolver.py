import requests
import logging
from functools import lru_cache
from typing import List, Dict, Any, Optional
from config.settings import settings

logger = logging.getLogger(__name__)

class MetadataResolver:
    """
    元数据解析器
    通过调用 Java 后端 API 获取表和字段的真实元数据，用于血缘验证。
    """
    
    def __init__(self, base_url: str = None):
        self.base_url = f"{base_url or settings.URGS_API_URL}/api/internal/metadata"
        
    @lru_cache(maxsize=128)
    def get_table_metadata(self, full_table_name: str) -> Optional[Dict[str, Any]]:
        """
        获取表的元数据（包含字段列表）
        使用 lru_cache 减少对 API 的重复调用。
        """
        try:
            url = f"{self.base_url}/table-fields"
            params = {"fullName": full_table_name}
            
            response = requests.get(url, params=params, timeout=30)
            if response.status_code == 200:
                data = response.json()
                if data.get("success"):
                    return {
                        "table": data.get("table"),
                        "fields": data.get("fields", []),
                        "field_names": {f["name"].upper() for f in data.get("fields", [])}
                    }
                else:
                    logger.warning(f"Metadata API returned error for {full_table_name}: {data.get('message')}")
            else:
                logger.error(f"Metadata API failed for {full_table_name}: HTTP {response.status_code}")
        except Exception as e:
            logger.error(f"Error calling Metadata API for {full_table_name}: {e}")
            
        return None

    def validate_column(self, table_name: str, column_name: str) -> Dict[str, Any]:
        """
        验证字段在表中是否存在，并返回置信度。
        
        置信度级别：
        - HIGH: 字段完全匹配
        - MEDIUM: 模糊匹配（如忽略下划线）或处理别名
        - LOW: 找不到字段
        """
        if not table_name or not column_name or column_name == "*":
            return {"exists": True, "confidence": "HIGH", "note": "Skip validation for complex/empty/star"}

        metadata = self.get_table_metadata(table_name)
        if not metadata:
            # 找不到表的元数据，无法验证，保持中立
            return {"exists": None, "confidence": "MEDIUM", "note": "Table metadata not found"}

        field_names = metadata["field_names"]
        col_upper = column_name.upper()

        # 1. 完全匹配
        if col_upper in field_names:
            return {"exists": True, "confidence": "HIGH"}

        # 2. 模糊匹配（去掉下划线对比，处理某些方言差异）
        col_clean = col_upper.replace("_", "")
        for fn in field_names:
            if fn.replace("_", "") == col_clean:
                return {
                    "exists": True, 
                    "confidence": "MEDIUM", 
                    "suggested_name": fn,
                    "note": "Fuzzy match by removing underscores"
                }

        # 3. 未找到
        return {
            "exists": False, 
            "confidence": "LOW", 
            "note": f"Column {column_name} not found in model_field for table {table_name}"
        }

    def get_table_fields(self, table_name: str) -> List[str]:
        """获取表的所有字段名，用于 SELECT * 展开"""
        metadata = self.get_table_metadata(table_name)
        if metadata:
            return [f["name"] for f in metadata["fields"]]
        return []
