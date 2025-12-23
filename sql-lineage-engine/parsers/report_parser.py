from typing import Dict, Any, List

class ReportParser:
    def parse_report_metadata(self, metadata: Dict[str, Any]) -> List[Dict[str, Any]]:
        """
        Parse report metadata to extract lineage.
        Expected format:
        {
            "report_name": "Sales Report",
            "indicators": [
                {
                    "name": "Total Sales",
                    "logic": "SUM(amount)",
                    "source_table": "orders",
                    "source_column": "amount"
                }
            ],
            "charts": [
                {
                    "name": "Sales by Region",
                    "source_table": "region_sales",
                    "columns": ["region", "sales"]
                }
            ]
        }
        """
        lineage = []
        report_name = metadata.get("report_name", "Unknown Report")
        
        # Parse Indicators
        for ind in metadata.get("indicators", []):
            lineage.append({
                "type": "indicator",
                "report": report_name,
                "name": ind.get("name"),
                "logic": ind.get("logic"),
                "source_table": ind.get("source_table"),
                "source_column": ind.get("source_column")
            })
            
        # Parse Charts (Report usage)
        for chart in metadata.get("charts", []):
            source_table = chart.get("source_table")
            for col in chart.get("columns", []):
                lineage.append({
                    "type": "chart_usage",
                    "report": report_name,
                    "chart": chart.get("name"),
                    "source_table": source_table,
                    "source_column": col
                })
                
        return lineage
