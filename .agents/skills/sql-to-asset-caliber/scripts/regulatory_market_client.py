#!/usr/bin/env python3
"""Portable client for regulatory evidence and confirmed asset-caliber updates."""

from __future__ import annotations

import argparse
import json
import os
import sys
from dataclasses import dataclass
from typing import Any
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlencode, urlparse
from urllib.request import Request, urlopen


DEFAULT_TIMEOUT_SECONDS = 20.0
MAX_TIMEOUT_SECONDS = 300.0
REGULATORY_COMMANDS = {
    "search",
    "table",
    "element",
    "codes",
    "relationships",
    "table-bundle",
}


class ClientError(RuntimeError):
    """A safe, user-facing client error."""


def _first_env(*names: str) -> str:
    for name in names:
        value = os.getenv(name, "").strip()
        if value:
            return value
    return ""


def _is_truthy(value: str) -> bool:
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _positive_int(value: str) -> int:
    parsed = int(value)
    if parsed <= 0:
        raise argparse.ArgumentTypeError("must be greater than zero")
    return parsed


def _positive_float(value: str) -> float:
    parsed = float(value)
    if parsed <= 0 or parsed > MAX_TIMEOUT_SECONDS:
        raise argparse.ArgumentTypeError(
            f"must be greater than zero and no more than {MAX_TIMEOUT_SECONDS:g}"
        )
    return parsed


def _normalize_allowed_systems(raw_value: str) -> str:
    systems = [item.strip() for item in raw_value.split(",") if item.strip()]
    if not systems:
        raise ClientError(
            "missing allowed systems; set URGS_ALLOWED_SYSTEMS or pass --allowed-systems"
        )
    if any(any(character in item for character in "\r\n\t") for item in systems):
        raise ClientError("allowed systems contain invalid control characters")
    if any(item.upper() == "ALL" for item in systems):
        if len(systems) != 1:
            raise ClientError("ALL cannot be combined with specific system codes")
        if not _is_truthy(os.getenv("URGS_ALLOW_ALL_SYSTEMS", "")):
            raise ClientError(
                "ALL access is disabled; an operator must set URGS_ALLOW_ALL_SYSTEMS=1"
            )
        return "ALL"
    return ",".join(dict.fromkeys(systems))


@dataclass(frozen=True)
class ClientConfig:
    base_url: str
    token: str
    allowed_systems: str
    auth_header: str
    auth_prefix: str
    timeout_seconds: float

    @classmethod
    def from_args(cls, args: argparse.Namespace) -> "ClientConfig":
        base_url = (args.base_url or _first_env("URGS_API_URL")).strip().rstrip("/")
        parsed_url = urlparse(base_url)
        if parsed_url.scheme not in {"http", "https"} or not parsed_url.netloc:
            raise ClientError(
                "missing or invalid API URL; set URGS_API_URL or pass --base-url"
            )

        token = _first_env("URGS_INTERNAL_API_TOKEN")
        if not token:
            raise ClientError(
                "missing internal API token; set URGS_INTERNAL_API_TOKEN"
            )

        raw_allowed_systems = args.allowed_systems or os.getenv("URGS_ALLOWED_SYSTEMS", "")
        allowed_systems = (
            _normalize_allowed_systems(raw_allowed_systems)
            if args.command in REGULATORY_COMMANDS or raw_allowed_systems.strip()
            else ""
        )
        auth_header = _first_env("URGS_INTERNAL_API_AUTH_HEADER") or "Authorization"
        auth_prefix = os.getenv(
            "URGS_INTERNAL_API_AUTH_PREFIX",
            "Bearer ",
        )
        if not auth_header or any(character in auth_header for character in "\r\n"):
            raise ClientError("internal API auth header is invalid")
        if any(character in auth_prefix for character in "\r\n"):
            raise ClientError("internal API auth prefix is invalid")

        return cls(
            base_url=base_url,
            token=token,
            allowed_systems=allowed_systems,
            auth_header=auth_header,
            auth_prefix=auth_prefix,
            timeout_seconds=args.timeout,
        )


class RegulatoryMarketClient:
    def __init__(self, config: ClientConfig) -> None:
        self.config = config

    def search(
        self, keyword: str, system_code: str | None, limit: int
    ) -> dict[str, Any]:
        return self._request(
            "GET",
            "/api/internal/regulatory-market/search",
            query={
                "keyword": keyword,
                "systemCode": system_code,
                "allowedSystems": self.config.allowed_systems,
                "limit": min(limit, 50),
            },
        )

    def get_table(self, table_id: int, element_limit: int) -> dict[str, Any]:
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/tables/{table_id}",
            query={
                "allowedSystems": self.config.allowed_systems,
                "elementLimit": min(element_limit, 100),
            },
        )

    def get_element(self, element_id: int) -> dict[str, Any]:
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/elements/{element_id}",
            query={"allowedSystems": self.config.allowed_systems},
        )

    def get_code_values(self, table_code: str, limit: int) -> dict[str, Any]:
        return self._request(
            "GET",
            f"/api/internal/regulatory-market/code-tables/{quote(table_code, safe='')}/values",
            query={
                "allowedSystems": self.config.allowed_systems,
                "limit": min(limit, 500),
            },
        )

    def get_relationships(self, table_ids: list[int]) -> dict[str, Any]:
        return self._request(
            "POST",
            "/api/internal/regulatory-market/relationships",
            payload={
                "tableIds": table_ids,
                "allowedSystems": self.config.allowed_systems,
            },
        )

    def get_table_bundle(
        self, table_id: int, element_limit: int, code_limit: int
    ) -> dict[str, Any]:
        table = self.get_table(table_id, element_limit)
        code_tables: dict[str, dict[str, Any]] = {}
        warnings: list[str] = []

        if table.get("elementsTruncated"):
            warnings.append(
                "监管表字段/指标超过接口上限，本次语义包不完整；请补充元素分页接口后再做完整回填。"
            )

        code_table_codes = sorted(
            {
                str(element.get("codeTableCode")).strip()
                for element in table.get("elements") or []
                if element.get("codeTableCode")
                and str(element.get("codeTableCode")).strip()
            }
        )
        for table_code in code_table_codes:
            try:
                code_tables[table_code] = self.get_code_values(table_code, code_limit)
            except ClientError as exc:
                warnings.append(f"码表 {table_code} 获取失败：{exc}")

        return {
            "complete": not warnings,
            "table": table,
            "codeTables": code_tables,
            "warnings": warnings,
        }

    def resolve_asset_table(
        self, requester_user_id: int, system_code: str, table_name: str
    ) -> dict[str, Any]:
        return self._request(
            "GET",
            "/api/internal/asset-caliber/tables/resolve",
            query={
                "requesterUserId": requester_user_id,
                "systemCode": system_code,
                "tableName": table_name,
            },
        )

    def get_asset_table(
        self, requester_user_id: int, table_id: int
    ) -> dict[str, Any]:
        return self._request(
            "GET",
            f"/api/internal/asset-caliber/tables/{quote(table_id, safe='')}",
            query={"requesterUserId": requester_user_id},
        )

    def preview_caliber(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request(
            "POST", "/api/internal/asset-caliber/preview", payload=payload
        )

    def apply_caliber(self, payload: dict[str, Any]) -> dict[str, Any]:
        return self._request(
            "POST", "/api/internal/asset-caliber/apply", payload=payload
        )

    def _request(
        self,
        method: str,
        path: str,
        *,
        query: dict[str, Any] | None = None,
        payload: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        normalized_query = {
            key: value
            for key, value in (query or {}).items()
            if value is not None and value != ""
        }
        url = self.config.base_url + path
        if normalized_query:
            url += "?" + urlencode(normalized_query)

        data = None
        headers = {
            self.config.auth_header: self.config.auth_prefix + self.config.token,
            "Accept": "application/json",
            "User-Agent": "sql-to-asset-caliber/1",
        }
        if payload is not None:
            data = json.dumps(payload, ensure_ascii=False).encode("utf-8")
            headers["Content-Type"] = "application/json; charset=utf-8"

        request = Request(url, data=data, headers=headers, method=method)
        try:
            with urlopen(request, timeout=self.config.timeout_seconds) as response:
                response_body = response.read().decode("utf-8")
        except HTTPError as exc:
            response_body = exc.read().decode("utf-8", errors="replace").strip()
            detail = response_body[:1000] if response_body else "no response body"
            raise ClientError(f"HTTP {exc.code}: {detail}") from exc
        except URLError as exc:
            raise ClientError(f"request failed: {exc.reason}") from exc
        except TimeoutError as exc:
            raise ClientError("request timed out") from exc

        try:
            result = json.loads(response_body)
        except json.JSONDecodeError as exc:
            raise ClientError("API returned invalid JSON") from exc
        if not isinstance(result, dict):
            raise ClientError("API returned a non-object JSON response")
        return result


def _build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description="Read regulatory evidence and preview/apply asset business caliber as JSON."
    )
    parser.add_argument(
        "--base-url",
        help="URGS API base URL; defaults to URGS_API_URL",
    )
    parser.add_argument(
        "--allowed-systems",
        help="comma-separated authorized system codes; defaults to URGS_ALLOWED_SYSTEMS",
    )
    parser.add_argument(
        "--timeout",
        type=_positive_float,
        default=DEFAULT_TIMEOUT_SECONDS,
        help=f"request timeout in seconds (default: {DEFAULT_TIMEOUT_SECONDS:g})",
    )

    subparsers = parser.add_subparsers(dest="command", required=True)

    search_parser = subparsers.add_parser("search", help="search tables, elements and code tables")
    search_parser.add_argument("--keyword", default="")
    search_parser.add_argument("--system-code")
    search_parser.add_argument("--limit", type=_positive_int, default=20)

    table_parser = subparsers.add_parser("table", help="get one regulatory table and its elements")
    table_parser.add_argument("--table-id", type=_positive_int, required=True)
    table_parser.add_argument("--element-limit", type=_positive_int, default=100)

    element_parser = subparsers.add_parser("element", help="get one field or indicator")
    element_parser.add_argument("--element-id", type=_positive_int, required=True)

    codes_parser = subparsers.add_parser("codes", help="get the current values of one code table")
    codes_parser.add_argument("--table-code", required=True)
    codes_parser.add_argument("--limit", type=_positive_int, default=200)

    relationships_parser = subparsers.add_parser(
        "relationships", help="get confirmed relationships for regulatory tables"
    )
    relationships_parser.add_argument(
        "--table-id", type=_positive_int, action="append", required=True
    )

    bundle_parser = subparsers.add_parser(
        "table-bundle", help="get one table, its elements, bindings and referenced code values"
    )
    bundle_parser.add_argument("--table-id", type=_positive_int, required=True)
    bundle_parser.add_argument("--element-limit", type=_positive_int, default=100)
    bundle_parser.add_argument("--code-limit", type=_positive_int, default=500)

    asset_resolve_parser = subparsers.add_parser(
        "asset-resolve", help="resolve one regulatory asset table exactly"
    )
    asset_resolve_parser.add_argument("--system-code", required=True)
    asset_resolve_parser.add_argument("--table-name", required=True)

    asset_table_parser = subparsers.add_parser(
        "asset-table", help="read one regulatory table and its current caliber"
    )
    asset_table_parser.add_argument("--table-id", type=_positive_int, required=True)

    preview_parser = subparsers.add_parser(
        "caliber-preview", help="validate and preview a caliber change JSON file"
    )
    preview_parser.add_argument("--request-file", required=True)

    apply_parser = subparsers.add_parser(
        "caliber-apply", help="apply a previously reviewed caliber change JSON file"
    )
    apply_parser.add_argument("--request-file", required=True)
    apply_parser.add_argument(
        "--confirm",
        action="store_true",
        required=True,
        help="explicitly confirm applying the reviewed changes",
    )
    return parser


def _requester_user_id() -> int:
    raw_value = os.getenv("URGS_REQUESTER_USER_ID", "").strip()
    if not raw_value:
        raise ClientError(
            "missing requester user; set URGS_REQUESTER_USER_ID for asset operations"
        )
    try:
        return _positive_int(raw_value)
    except (ValueError, argparse.ArgumentTypeError) as exc:
        raise ClientError("URGS_REQUESTER_USER_ID must be a positive integer") from exc


def _load_change_request(path: str, requester_user_id: int, confirmed: bool) -> dict[str, Any]:
    try:
        with open(path, "r", encoding="utf-8") as handle:
            payload = json.load(handle)
    except OSError as exc:
        raise ClientError(f"cannot read request file: {exc}") from exc
    except json.JSONDecodeError as exc:
        raise ClientError(f"request file is not valid JSON: {exc}") from exc
    if not isinstance(payload, dict):
        raise ClientError("request file must contain one JSON object")
    embedded_user_id = payload.get("requesterUserId")
    if embedded_user_id is not None and embedded_user_id != requester_user_id:
        raise ClientError(
            "requesterUserId in request file does not match URGS_REQUESTER_USER_ID"
        )
    payload["requesterUserId"] = requester_user_id
    payload["confirmed"] = confirmed
    return payload


def _execute(args: argparse.Namespace, client: RegulatoryMarketClient) -> dict[str, Any]:
    if args.command == "search":
        return client.search(args.keyword, args.system_code, args.limit)
    if args.command == "table":
        return client.get_table(args.table_id, args.element_limit)
    if args.command == "element":
        return client.get_element(args.element_id)
    if args.command == "codes":
        return client.get_code_values(args.table_code, args.limit)
    if args.command == "relationships":
        return client.get_relationships(args.table_id)
    if args.command == "table-bundle":
        return client.get_table_bundle(
            args.table_id, args.element_limit, args.code_limit
        )
    if args.command == "asset-resolve":
        return client.resolve_asset_table(
            _requester_user_id(), args.system_code, args.table_name
        )
    if args.command == "asset-table":
        return client.get_asset_table(_requester_user_id(), args.table_id)
    if args.command == "caliber-preview":
        requester_user_id = _requester_user_id()
        return client.preview_caliber(
            _load_change_request(args.request_file, requester_user_id, False)
        )
    if args.command == "caliber-apply":
        requester_user_id = _requester_user_id()
        return client.apply_caliber(
            _load_change_request(args.request_file, requester_user_id, args.confirm)
        )
    raise ClientError(f"unsupported command: {args.command}")


def main() -> int:
    parser = _build_parser()
    args = parser.parse_args()
    try:
        config = ClientConfig.from_args(args)
        result = _execute(args, RegulatoryMarketClient(config))
    except ClientError as exc:
        print(f"error: {exc}", file=sys.stderr)
        return 1
    print(json.dumps(result, ensure_ascii=False, indent=2, sort_keys=True))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
