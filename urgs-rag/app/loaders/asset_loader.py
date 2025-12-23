import requests
from typing import List, Dict, Any
from langchain_core.documents import Document

class AssetLoader:
    def __init__(self, api_url: str):
        self.api_url = api_url

    def load(self) -> List[Document]:
        """
        Load assets from URGS-API.
        Expected API return format: List of asset objects.
        """
        try:
            # Assume API URL is complete (e.g. http://localhost:8080/api/assets)
            response = requests.get(self.api_url)
            response.raise_for_status()
            data = response.json()
            
            if isinstance(data, dict) and "data" in data:
                 data = data["data"] # Handle wrapped response
            
            if not isinstance(data, list):
                print(f"Unexpected API response format: {type(data)}")
                return []

            documents = []
            for item in data:
                doc = self._process_item(item)
                if doc:
                    documents.append(doc)
            
            return documents

        except Exception as e:
            print(f"Error loading assets from {self.api_url}: {e}")
            return []

    def _process_item(self, item: Dict[str, Any]) -> Document:
        """
        Convert structured asset item to natural language document.
        """
        # Customize this template based on actual asset structure
        template = (
            "监管资产信息：\n"
            f"名称：{item.get('assetName', '未知')}\n"
            f"编码：{item.get('assetCode', '未知')}\n"
            f"类型：{item.get('assetType', '未知')}\n"
            f"部门：{item.get('department', '未知')}\n"
            f"描述：{item.get('description', '无')}\n"
            f"业务规则：{item.get('businessRules', '无')}\n"
        )
        
        metadata = {
            "source_type": "regulatory_asset",
            "asset_id": item.get("id"),
            "asset_code": item.get('assetCode')
        }
        
        return Document(page_content=template, metadata=metadata)
