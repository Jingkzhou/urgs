from typing import List, Dict
from neo4j import GraphDatabase
from langchain_core.documents import Document

class LineageLoader:
    def __init__(self, uri: str, auth: tuple):
        self.driver = GraphDatabase.driver(uri, auth=auth)

    def close(self):
        self.driver.close()

    def load(self) -> List[Document]:
        """
        Load lineage paths from Neo4j and convert to text.
        Focuses on Table -> Table relationships.
        """
        query = """
        MATCH (s:Table)-[r]->(t:Table)
        RETURN s.name as source, type(r) as rel, t.name as target
        LIMIT 10000
        """
        # Note: You can expand this to include column lineage or more complex paths
        
        documents = []
        try:
            with self.driver.session() as session:
                result = session.run(query)
                for record in result:
                    text = self._record_to_text(record)
                    doc = Document(
                        page_content=text,
                        metadata={
                            "source_type": "lineage",
                            "source_table": record["source"],
                            "target_table": record["target"]
                        }
                    )
                    documents.append(doc)
        except Exception as e:
            print(f"Error loading lineage from Neo4j: {e}")
            
        return documents

    def _record_to_text(self, record) -> str:
        """
        Convert a lineage record to a natural language sentence.
        """
        # Translate relationship types if needed
        rel_map = {
            "DERIVES_TO": "流向",
            "JOINS": "关联",
            "FILTERS": "过滤",
            "CALLS": "调用",
            "REFERENCES": "引用"
        }
        rel_zh = rel_map.get(record['rel'], record['rel'])
        
        return f"表 {record['source']} 的数据{rel_zh}表 {record['target']}。"
