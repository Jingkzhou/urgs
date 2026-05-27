import json
import hashlib
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional

logger = logging.getLogger(__name__)


class MetadataPackResolver:
    """Resolve table and column metadata from a fixed local metadata-pack.json."""

    def __init__(self, metadata_file: str = None):
        self.metadata_file = metadata_file
        self.pack: Dict[str, Any] = {}
        self.pack_hash: Optional[str] = None
        self.tables_by_qualified: Dict[str, Dict[str, Any]] = {}
        self.tables_by_name: Dict[str, List[Dict[str, Any]]] = {}
        if metadata_file:
            self.load(metadata_file)

    def load(self, metadata_file: str):
        path = Path(metadata_file)
        if not path.exists():
            logger.warning("Metadata pack not found: %s", metadata_file)
            return
        raw = path.read_bytes()
        self.pack_hash = hashlib.sha256(raw).hexdigest()
        self.pack = json.loads(raw.decode("utf-8"))
        self._index_tables(self.pack.get("tables") or [])
        logger.info(
            "Metadata pack loaded: %s tables=%s fields=%s",
            metadata_file,
            self.pack.get("tableCount"),
            self.pack.get("fieldCount"),
        )

    def _index_tables(self, tables: List[Dict[str, Any]]):
        for table in tables:
            normalized_table = dict(table)
            owner = self._normalize_name(normalized_table.get("owner"))
            name = self._normalize_name(normalized_table.get("name"))
            qualified = self._normalize_table_name(
                normalized_table.get("qualifiedName") or self._join(owner, name)
            )
            normalized_table["owner"] = owner
            normalized_table["name"] = name
            normalized_table["qualifiedName"] = qualified
            normalized_table["field_names"] = [
                self._normalize_name(field.get("name"))
                for field in normalized_table.get("fields", [])
                if field.get("name")
            ]
            normalized_table["fields"] = [
                {**field, "name": self._normalize_name(field.get("name"))}
                for field in normalized_table.get("fields", [])
                if field.get("name")
            ]
            self.tables_by_qualified[qualified] = normalized_table
            self.tables_by_name.setdefault(name, []).append(normalized_table)

    def get_table_metadata(self, full_table_name: str) -> Optional[Dict[str, Any]]:
        normalized = self._normalize_table_name(full_table_name)
        if not normalized:
            return None
        direct = self.tables_by_qualified.get(normalized)
        if direct:
            return direct
        short_name = normalized.split(".")[-1]
        candidates = self.tables_by_name.get(short_name, [])
        if len(candidates) == 1:
            return candidates[0]
        return None

    def validate_column(self, table_name: str, column_name: str) -> Dict[str, Any]:
        if not table_name or not column_name or column_name == "*":
            return {"exists": True, "confidence": "HIGH", "note": "Skip validation for complex/empty/star"}

        metadata = self.get_table_metadata(table_name)
        if not metadata:
            return {
                "exists": None,
                "confidence": "MEDIUM",
                "note": f"Table metadata not found for {table_name}",
                "metadata_matched": False,
            }

        col_upper = self._normalize_name(column_name)
        field_names = metadata.get("field_names") or []
        if col_upper in field_names:
            return {"exists": True, "confidence": "HIGH", "metadata_matched": True}

        col_clean = col_upper.replace("_", "")
        for field_name in field_names:
            if field_name.replace("_", "") == col_clean:
                return {
                    "exists": True,
                    "confidence": "MEDIUM",
                    "suggested_name": field_name,
                    "note": "Fuzzy match by removing underscores",
                    "metadata_matched": True,
                }

        return {
            "exists": False,
            "confidence": "LOW",
            "note": f"Column {column_name} not found in metadata pack for table {table_name}",
            "ambiguity_code": "MISSING_COLUMN",
            "metadata_matched": False,
        }

    def get_table_fields(self, table_name: str) -> List[str]:
        metadata = self.get_table_metadata(table_name)
        if not metadata:
            return []
        fields = metadata.get("fields") or []
        return [field.get("name") for field in fields if field.get("name")]

    def has_metadata(self) -> bool:
        return bool(self.tables_by_qualified)

    def _normalize_table_name(self, name: str) -> str:
        if not name:
            return ""
        clean = str(name).replace("`", "").replace('"', "").replace("'", "").strip()
        parts = [self._normalize_name(part) for part in clean.split(".") if part.strip()]
        return ".".join(parts)

    def _normalize_name(self, value: str) -> str:
        return "" if value is None else str(value).strip().upper()

    def _join(self, owner: str, name: str) -> str:
        return f"{owner}.{name}" if owner else name
