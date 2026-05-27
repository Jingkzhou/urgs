import logging
from functools import lru_cache
from typing import List, Dict, Any, Optional
from utils.metadata_pack_resolver import MetadataPackResolver

logger = logging.getLogger(__name__)

class MetadataResolver:
    """
    元数据解析器
    通过调用 Java 后端 API 获取表和字段的真实元数据，用于血缘验证。
    """
    
    def __init__(self, base_url: str = None, metadata_file: str = None):
        self.base_url = base_url
        self.pack_resolver = MetadataPackResolver(metadata_file) if metadata_file else None
        self.runtime_tables_by_qualified: Dict[str, Dict[str, Any]] = {}
        self.runtime_tables_by_name: Dict[str, List[Dict[str, Any]]] = {}

    @property
    def metadata_pack_hash(self) -> Optional[str]:
        return self.pack_resolver.pack_hash if self.pack_resolver else None

    def has_metadata(self) -> bool:
        return bool(
            (self.pack_resolver and self.pack_resolver.has_metadata())
            or self.runtime_tables_by_qualified
        )

    def register_table_fields(self, table_name: str, field_names: List[str], source: str = "sql_context"):
        """Register fields inferred inside the current SQL file, used as a local metadata fallback."""
        normalized_table = self._normalize_table_name(table_name)
        fields = []
        seen = set()
        for name in field_names or []:
            normalized_field = self._normalize_name(name)
            if not normalized_field or normalized_field in seen:
                continue
            seen.add(normalized_field)
            fields.append({
                "name": normalized_field,
                "sortOrder": len(fields) + 1,
                "metadataSource": source,
            })

        if not normalized_table or not fields:
            return

        short_name = normalized_table.split(".")[-1]
        table = {
            "owner": normalized_table.rsplit(".", 1)[0] if "." in normalized_table else "",
            "name": short_name,
            "qualifiedName": normalized_table,
            "fields": fields,
            "field_names": [field["name"] for field in fields],
            "metadataSource": source,
        }
        self.runtime_tables_by_qualified[normalized_table] = table
        existing = [
            item for item in self.runtime_tables_by_name.get(short_name, [])
            if item.get("qualifiedName") != normalized_table
        ]
        existing.append(table)
        self.runtime_tables_by_name[short_name] = existing
        try:
            self.get_table_metadata.cache_clear()
        except AttributeError:
            pass
        
    @lru_cache(maxsize=128)
    def get_table_metadata(self, full_table_name: str) -> Optional[Dict[str, Any]]:
        """
        获取表的元数据（包含字段列表）
        使用 lru_cache 减少对 API 的重复调用。
        """
        runtime_metadata = self._get_runtime_table_metadata(full_table_name)
        if self.pack_resolver:
            pack_metadata = self.pack_resolver.get_table_metadata(full_table_name)
            if pack_metadata and pack_metadata.get("field_names"):
                return pack_metadata
            if runtime_metadata:
                return runtime_metadata
            return pack_metadata
        if runtime_metadata:
            return runtime_metadata
        # 临时禁用元数据 API 回查，避免血缘分析期间拖慢主系统。
        logger.info("Metadata API lookup disabled for table: %s", full_table_name)
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

        if self.pack_resolver:
            pack_metadata = self.pack_resolver.get_table_metadata(table_name)
            if pack_metadata and pack_metadata.get("field_names"):
                return self.pack_resolver.validate_column(table_name, column_name)
            runtime_result = self._validate_runtime_column(table_name, column_name)
            if runtime_result:
                return runtime_result
            return self.pack_resolver.validate_column(table_name, column_name)

        runtime_result = self._validate_runtime_column(table_name, column_name)
        if runtime_result:
            return runtime_result

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
        if self.pack_resolver:
            fields = self.pack_resolver.get_table_fields(table_name)
            if fields:
                return fields
        runtime_metadata = self._get_runtime_table_metadata(table_name)
        if runtime_metadata:
            return [
                field.get("name")
                for field in runtime_metadata.get("fields", [])
                if field.get("name")
            ]
        metadata = self.get_table_metadata(table_name)
        if metadata:
            return [f["name"] for f in metadata["fields"]]
        return []

    def _get_runtime_table_metadata(self, full_table_name: str) -> Optional[Dict[str, Any]]:
        normalized = self._normalize_table_name(full_table_name)
        if not normalized:
            return None
        direct = self.runtime_tables_by_qualified.get(normalized)
        if direct:
            return direct
        short_name = normalized.split(".")[-1]
        candidates = self.runtime_tables_by_name.get(short_name, [])
        if len(candidates) == 1:
            return candidates[0]
        return None

    def _validate_runtime_column(self, table_name: str, column_name: str) -> Optional[Dict[str, Any]]:
        metadata = self._get_runtime_table_metadata(table_name)
        if not metadata:
            return None

        col_upper = self._normalize_name(column_name)
        field_names = metadata.get("field_names") or []
        if col_upper in field_names:
            return {
                "exists": True,
                "confidence": "HIGH",
                "metadata_matched": True,
                "note": "Column matched in SQL file field context",
            }

        col_clean = col_upper.replace("_", "")
        for field_name in field_names:
            if field_name.replace("_", "") == col_clean:
                return {
                    "exists": True,
                    "confidence": "MEDIUM",
                    "suggested_name": field_name,
                    "note": "Fuzzy match in SQL file field context",
                    "metadata_matched": True,
                }

        return {
            "exists": False,
            "confidence": "LOW",
            "note": f"Column {column_name} not found in SQL file field context for table {table_name}",
            "ambiguity_code": "MISSING_COLUMN",
            "metadata_matched": False,
        }

    def _normalize_table_name(self, name: str) -> str:
        if not name:
            return ""
        clean = str(name).replace("`", "").replace('"', "").replace("'", "").strip()
        parts = [self._normalize_name(part) for part in clean.split(".") if part.strip()]
        return ".".join(parts)

    def _normalize_name(self, value: str) -> str:
        return "" if value is None else str(value).strip().upper()
