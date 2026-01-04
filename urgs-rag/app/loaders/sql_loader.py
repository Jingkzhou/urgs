import os
import glob
from typing import List
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter, Language
from langchain_core.documents import Document

class SqlLoader:
    """
    SQL 文件加载器。
    
    专门用于处理 .sql 后缀的数据库脚本文件，并注入相应的元数据，
    支持专门针对 SQL 语法的切分逻辑。
    """
    def __init__(self, storage_path: str, split_documents: bool = True):
        """
        初始化 SQL 加载器。

        Args:
            storage_path (str): SQL 文件所在目录。
            split_documents (bool): 加载后是否进行切分。
        """
        self.storage_path = storage_path
        self.split_documents = split_documents

    def load(self) -> List[Document]:
        """
        递归加载目录下所有的 SQL 文件。

        Returns:
            List[Document]: SQL 文档列表。
        """
        if not os.path.exists(self.storage_path):
            return []

        documents = []
        # 使用 glob 递归查找所有 .sql 文件
        sql_files = glob.glob(os.path.join(self.storage_path, "**/*.sql"), recursive=True)
        
        for file_path in sql_files:
            try:
                # SQL 文件通常为 UTF-8 编码
                loader = TextLoader(file_path, encoding='utf-8')
                docs = loader.load()
                # 为每个文档注入 SQL 特有的元数据
                for doc in docs:
                    doc.metadata["source_type"] = "sql_code"
                    doc.metadata["file_name"] = os.path.basename(file_path)
                    doc.metadata["file_path"] = file_path
                documents.extend(docs)
            except Exception as e:
                print(f"加载 SQL 文件出错 {file_path}: {e}")

        # 如果启用切分，则调用 SQL 专用切分函数
        if self.split_documents:
            return self.split_documents_func(documents)
        return documents

    def split_documents_func(self, documents: List[Document]) -> List[Document]:
        """
        使用针对代码/SQL 优化的分隔符进行文档切分。
        
        优先按分号和换行符切分，以保持 SQL 语句的相对完整。
        """
        splitter = RecursiveCharacterTextSplitter(
            separators=[";\n\n", ";\n", ";", "\n\n", "\n", " ", ""],
            chunk_size=2000,
            chunk_overlap=200
        )
        return splitter.split_documents(documents)
