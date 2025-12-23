import os
import glob
from typing import List
from langchain_community.document_loaders import TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter, Language
from langchain_core.documents import Document

class SqlLoader:
    def __init__(self, storage_path: str):
        self.storage_path = storage_path

    def load(self) -> List[Document]:
        """
        Load all SQL files from the directory and its subdirectories.
        """
        if not os.path.exists(self.storage_path):
            return []

        documents = []
        # Recursive glob for .sql files
        sql_files = glob.glob(os.path.join(self.storage_path, "**/*.sql"), recursive=True)
        
        for file_path in sql_files:
            try:
                loader = TextLoader(file_path, encoding='utf-8')
                docs = loader.load()
                # Add metadata
                for doc in docs:
                    doc.metadata["source_type"] = "sql_code"
                    doc.metadata["file_name"] = os.path.basename(file_path)
                    doc.metadata["file_path"] = file_path
                documents.extend(docs)
            except Exception as e:
                print(f"Error loading SQL file {file_path}: {e}")

        return self.split_documents(documents)

    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        Split SQL documents using Language-aware splitter.
        """
        splitter = RecursiveCharacterTextSplitter(
            separators=[";\n\n", ";\n", ";", "\n\n", "\n", " ", ""],
            chunk_size=2000,
            chunk_overlap=200
        )
        return splitter.split_documents(documents)
