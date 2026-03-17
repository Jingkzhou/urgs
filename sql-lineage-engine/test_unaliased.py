from parsers.indirect_flow_parser import IndirectFlowParser
from utils.metadata_resolver import MetadataResolver
import json
import logging

logging.basicConfig(level=logging.DEBUG)


def test_unaliased_columns():
    parser = IndirectFlowParser(dialect="mysql")

    # Mock the metadata resolver to return fake tables without hitting the API
    original_get_table_metadata = parser.resolver.get_table_metadata

    def mocked_get_table_metadata(full_table_name):
        if full_table_name == "users":
            return {
                "table": "users",
                "fields": [{"name": "id"}, {"name": "name"}, {"name": "created_at"}],
                "field_names": {"ID", "NAME", "CREATED_AT"},
            }
        elif full_table_name == "orders":
            return {
                "table": "orders",
                "fields": [
                    {"name": "order_id"},
                    {"name": "user_id"},
                    {"name": "order_date"},
                ],
                "field_names": {"ORDER_ID", "USER_ID", "ORDER_DATE"},
            }
        return None

    parser.resolver.get_table_metadata = mocked_get_table_metadata

    # Example SQL with unaliased columns (`id` in WHERE clause and SELECT)
    sql = """
    INSERT INTO target_table (uid, user_name, order_count)
    SELECT id, name, COUNT(order_id)
    FROM users 
    JOIN orders ON id = user_id
    GROUP BY id, name
    """

    print("Parsing SQL...")
    deps = parser.parse(sql)

    print("\nExtracted Dependencies:")
    print(json.dumps(deps, indent=2))


if __name__ == "__main__":
    test_unaliased_columns()
