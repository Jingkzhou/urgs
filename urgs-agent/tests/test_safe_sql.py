import sys
from unittest.mock import MagicMock, patch
import json

# Ensure project root is in path
sys.path.append("/Users/work/Documents/GitHub/urgs/urgs-agent")

from agent.tools.safe_sql_tool import execute_safe_sql


def test_limit_injection():
    print("\n🚀 Testing Mandatory LIMIT Injection...")

    with patch("pymysql.connect") as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

        # Mock fetchall to return dummy data
        mock_cursor.fetchall.return_value = [{"id": 1, "name": "test"}]

        # Test Case 1: No LIMIT
        sql_input = "SELECT * FROM users"
        execute_safe_sql.run(sql_input)

        # Verify LIMIT 20 was added
        call_args = mock_cursor.execute.call_args[0][0]
        print(f"Input: {sql_input}")
        print(f"Executed: {call_args}")
        if "LIMIT 20" in call_args:
            print("✅ LIMIT 20 successfully injected.")
        else:
            print("❌ Failed to inject LIMIT.")

        # Test Case 2: Existing LIMIT
        sql_input_limit = "SELECT * FROM users LIMIT 5"
        execute_safe_sql.run(sql_input_limit)
        call_args_limit = mock_cursor.execute.call_args[0][0]
        if "LIMIT 20" not in call_args_limit and "LIMIT 5" in call_args_limit:
            print("✅ Existing LIMIT preserved.")
        else:
            print(f"❌ Existing LIMIT messed up: {call_args_limit}")


def test_result_truncation():
    print("\n🚀 Testing Result Truncation...")

    with patch("pymysql.connect") as mock_connect:
        mock_conn = MagicMock()
        mock_cursor = MagicMock()
        mock_connect.return_value = mock_conn
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

        # Mock huge result
        huge_data = [
            {"col": "a" * 100} for _ in range(100)
        ]  # 100 * 100 char = 10000 chars > 5000
        mock_cursor.fetchall.return_value = huge_data

        result = execute_safe_sql.run("SELECT * FROM huge_table")

        print(f"Result Length: {len(result)}")
        if "..." in result and len(result) < 12000:  # 5000 + some warnings
            print("✅ Result successfully truncated.")
        else:
            print("❌ Result not truncated properly.")


if __name__ == "__main__":
    test_limit_injection()
    test_result_truncation()
