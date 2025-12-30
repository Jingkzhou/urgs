import sys
import os

# Add project root to path
sys.path.append("/Users/work/Documents/JLbankGit/URGS/sql-lineage-engine")

# Configure basic logging to see output
import logging
logging.basicConfig(level=logging.INFO)

try:
    from parsers.sql_parser import LineageParser
except ImportError as e:
    print(f"ImportError: {e}")
    sys.exit(1)

def test():
    print("Testing logging fix...")
    parser = LineageParser()
    
    # SQL that should trigger strong oracle detection
    # "DECODE(" is a strong signal for Oracle
    sql = "SELECT DECODE(col, 1, 'A', 'B') FROM dual"
    
    print(f"Parsing SQL: {sql}")
    try:
        # This will trigger logging.info inside parse
        result = parser.parse(sql)
        print("Success! Parse complete.")
    except Exception as e:
        print(f"FAILED with error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == "__main__":
    test()
