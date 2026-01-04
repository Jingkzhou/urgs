"""
数据摄入命令行工具 (Ingestion CLI)

该脚本负责从本地存储路径加载文档、处理 SQL 文件、进行知识精炼（QA生成），
最后将处理后的数据摄入到向量数据库中。
"""

import asyncio
import sys
import os

# 确保项目根目录在系统路径中，以便能够导入 app 模块
sys.path.append(os.getcwd())

from app.config import settings
from app.loaders.doc_loader import DocLoader
from app.loaders.sql_loader import SqlLoader
from app.services.refiner import knowledge_refiner
from app.services.vector_store import vector_store_service
import uuid

def main():
    """
    数据摄入主流程：
    1. 加载常规文档（PDF/DOCX/XLSX/TXT）
    2. 加载 SQL 文件
    3. 知识精炼（利用 LLM 生成问答对）
    4. 存入向量数据库
    """
    print(f"开始从路径摄入数据: {settings.DOC_STORAGE_PATH}")
    
    all_docs = []

    # 1. 加载常规文档 (PDF, DOCX, XLSX, TXT)
    print("--- 正在加载常规文档 ---")
    doc_loader = DocLoader(storage_path=settings.DOC_STORAGE_PATH, use_llm_clean=True, split_documents=False)
    docs = doc_loader.load()
    print(f"已加载 {len(docs)} 个文档快。")
    all_docs.extend(docs)

    # 2. 加载 SQL 文件
    print("--- 正在加载 SQL 文件 ---")
    # 复用相同的根目录，加载器会过滤出 .sql 文件
    sql_loader = SqlLoader(storage_path=settings.DOC_STORAGE_PATH, split_documents=False) 
    sql_docs = sql_loader.load()
    print(f"已加载 {len(sql_docs)} 个 SQL 块。")
    all_docs.extend(sql_docs)

    if not all_docs:
        print("未找到需要摄入的文档。")
        return

    print(f"待精炼的文档总数: {len(all_docs)}")

    # 为文档注入集合名称和父 ID (用于追溯)
    for doc in all_docs:
        doc.metadata["collection_name"] = settings.COLLECTION_NAME
        if not doc.metadata.get("parent_id"):
            doc.metadata["parent_id"] = uuid.uuid4().hex

    # 3. 知识精炼 (QA 对生成)
    print("--- 开始知识精炼 (生成问答对) ---")
    # 此步骤涉及 LLM 调用，可能耗时较长
    refined_docs = knowledge_refiner.refine_documents(all_docs)
    print(f"精炼完成。处理后的文档总数: {len(refined_docs)}")

    # 4. 向量数据库摄入
    print("--- 正在存入向量数据库 ---")
    vector_store_service.add_documents(refined_docs, collection_name=settings.COLLECTION_NAME)
    print("数据摄入完成！")

if __name__ == "__main__":
    main()
