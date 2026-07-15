import importlib.util
import json
import os
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import MagicMock, patch


MODULE_PATH = Path(__file__).parents[1] / "scripts" / "regulatory_market_client.py"
SPEC = importlib.util.spec_from_file_location("regulatory_market_client", MODULE_PATH)
MODULE = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MODULE
SPEC.loader.exec_module(MODULE)


class RegulatoryMarketClientTest(unittest.TestCase):

    def test_asset_commands_do_not_require_regulatory_system_scope(self):
        parser = MODULE._build_parser()
        args = parser.parse_args(["asset-table", "--table-id", "101"])
        environment = {
            "URGS_API_URL": "http://localhost:8080",
            "URGS_INTERNAL_API_TOKEN": "secret",
            "URGS_REQUESTER_USER_ID": "7",
        }

        with patch.dict(os.environ, environment, clear=True):
            config = MODULE.ClientConfig.from_args(args)

        self.assertEqual("", config.allowed_systems)

    def test_change_request_injects_trusted_user_and_confirmation(self):
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".json") as handle:
            json.dump({"tableId": 101, "elements": []}, handle)
            handle.flush()
            payload = MODULE._load_change_request(handle.name, 7, True)

        self.assertEqual(7, payload["requesterUserId"])
        self.assertTrue(payload["confirmed"])

    def test_change_request_rejects_mismatched_embedded_user(self):
        with tempfile.NamedTemporaryFile("w", encoding="utf-8", suffix=".json") as handle:
            json.dump({"requesterUserId": 8, "tableId": 101}, handle)
            handle.flush()
            with self.assertRaises(MODULE.ClientError):
                MODULE._load_change_request(handle.name, 7, False)

    def test_apply_uses_dedicated_asset_caliber_endpoint(self):
        config = MODULE.ClientConfig(
            base_url="http://localhost:8080",
            token="secret",
            allowed_systems="",
            auth_header="Authorization",
            auth_prefix="Bearer ",
            timeout_seconds=20,
        )
        response = MagicMock()
        response.read.return_value = b'{"updatedCount":1}'
        context = MagicMock()
        context.__enter__.return_value = response
        context.__exit__.return_value = False

        with patch.object(MODULE, "urlopen", return_value=context) as urlopen:
            result = MODULE.RegulatoryMarketClient(config).apply_caliber(
                {"tableId": 101, "confirmed": True}
            )

        request = urlopen.call_args.args[0]
        self.assertEqual(
            "http://localhost:8080/api/internal/asset-caliber/apply",
            request.full_url,
        )
        self.assertEqual(1, result["updatedCount"])

    def test_resolve_uses_regulatory_system_code_and_table_name(self):
        config = MODULE.ClientConfig(
            base_url="http://localhost:8080",
            token="secret",
            allowed_systems="",
            auth_header="Authorization",
            auth_prefix="Bearer ",
            timeout_seconds=20,
        )
        response = MagicMock()
        response.read.return_value = b'{"id":101}'
        context = MagicMock()
        context.__enter__.return_value = response
        context.__exit__.return_value = False

        with patch.object(MODULE, "urlopen", return_value=context) as urlopen:
            result = MODULE.RegulatoryMarketClient(config).resolve_asset_table(
                7, "1104", "LOAN_SUMMARY"
            )

        request_url = urlopen.call_args.args[0].full_url
        self.assertIn("systemCode=1104", request_url)
        self.assertIn("tableName=LOAN_SUMMARY", request_url)
        self.assertEqual(101, result["id"])


if __name__ == "__main__":
    unittest.main()
