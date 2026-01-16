import os
import shutil
import logging
import uuid
from typing import List, Optional
from app.config import settings
from app.loaders.doc_loader import DocLoader
from app.loaders.sql_loader import SqlLoader
from app.services.refiner import knowledge_refiner
from app.services.vector_store import vector_store_service

logger = logging.getLogger(__name__)

class IngestionService:
    """
    数据摄入服务类。
    
    负责管理本地文档存储、处理上传文件以及执行完整的 RAG 摄入流程。
    """
    def list_files(self, collection_name: str) -> List[dict]:
        """
        列出指定集合目录下的所有文件。

        Args:
            collection_name (str): 集合名称（对应文件夹名）。

        Returns:
            List[dict]: 包含文件名、大小和修改时间的文件列表。
        """
        base_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        if not os.path.exists(base_path):
            return []
            
        files = []
        for f in os.listdir(base_path):
            file_path = os.path.join(base_path, f)
            if os.path.isfile(file_path):
                files.append({
                    "name": f,
                    "size": os.path.getsize(file_path),
                    "last_modified": os.path.getmtime(file_path)
                })
        return files

    async def save_file(self, collection_name: str, filename: str, content: bytes) -> str:
        """
        将上传的文件保存到对应集合的目录中。

        Args:
            collection_name (str): 目标集合名称。
            filename (str): 文件名。
            content (bytes): 文件二进制内容。

        Returns:
            str: 保存后的本地文件路径。
        """
        base_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        os.makedirs(base_path, exist_ok=True)
        
        file_path = os.path.join(base_path, filename)
        with open(file_path, "wb") as f:
            f.write(content)
            
        return file_path

    def delete_file(self, collection_name: str, filename: str) -> bool:
        """
        从存储目录中删除文件。
        """
        file_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name, filename)
        if os.path.exists(file_path):
            os.remove(file_path)
            return True
        return False

    def delete_file_vectors(self, collection_name: str, filename: str) -> dict:
        """
        删除指定文件对应的向量切片与父文档。
        """
        if not collection_name or not filename:
            return {"status": "error", "message": "collection_name 和 filename 不能为空。"}
        return vector_store_service.delete_by_file(collection_name, filename)

    def run_ingestion(self, collection_name: str, filenames: Optional[str] = None, enable_qa: bool = False) -> dict:
        """
        为指定集合或集合中的特定文件执行摄入流程。

        流程包括：
        1. 路径检测
        2. 文档加载（自动区分 SQL 和常规文档）
        3. 元数据注入
        4. 知识精炼（可选，生成 QA 对）
        5. 写入向量数据库

        Args:
            collection_name (str): 目标集合名称。
            filenames (str, optional): 以逗号分隔的文件名列表。若为空，则处理目录下所有文件。
            enable_qa (bool): 是否启用全息知识增强（调用 LLM 生成 QA 等）。

        Returns:
            dict: 摄入结果统计。
        """
        source_path = os.path.join(settings.DOC_STORAGE_PATH, collection_name)
        
        if not os.path.exists(source_path):
             return {"status": "error", "message": f"目录 {source_path} 不存在。"}

        # 确定待处理的目标文件
        if filenames:
            # 处理逗号分隔的文件名
            fn_list = [f.strip() for f in filenames.split(",") if f.strip()]
            target_files = []
            for fn in fn_list:
                fp = os.path.join(source_path, fn)
                if os.path.exists(fp):
                    target_files.append(fp)
                else:
                    logger.warning(f"在 {collection_name} 中未找到文件 {fn}，已跳过。")
            
            if not target_files:
                return {"status": "error", "message": f"在 {collection_name} 中未找到请求的任何文件。"}
            logger.info(f"正在为集合 {collection_name} 中的 {len(target_files)} 个文件执行摄入...")
        else:
            logger.info(f"正在对集合 '{collection_name}' 进行全量摄入...")
            target_files = [os.path.join(source_path, f) for f in os.listdir(source_path) if os.path.isfile(os.path.join(source_path, f))]

        all_docs = []
        file_stats = {}

        # --- 引入幂等性逻辑：摄入前先物理清理旧数据 ---
        delete_list = [os.path.basename(f) for f in target_files]
        if delete_list:
            print(f"[RAG-Ingest] 正在清理旧版本向量以确保幂等性: {delete_list}")
            vector_store_service.delete_by_files(delete_list, collection_name=collection_name)
        # ----------------------------------------

        # 遍历并处理每个文件
        for fp in target_files:
            ext = os.path.splitext(fp)[1].lower()
            fname = os.path.basename(fp)
            try:
                # 区分 SQL 和其他文档，使用不同的加载器配置
                if ext == ".sql":
                    loader = SqlLoader(storage_path=os.path.dirname(fp), split_documents=False)
                    docs = loader.load()
                    # 过滤出当前正在处理的文件内容
                    docs = [d for d in docs if os.path.basename(d.metadata.get("file_path", "")) == fname]
                else:
                    # 修正：开启 split_documents=True，将整份文档切分为逻辑上的“父片段”（约1000字符）
                    # 这样在检索时，返回的是具体的相关段落，而不是整篇文档的开头。
                    loader = DocLoader(storage_path=fp, use_llm_clean=settings.ENABLE_LLM_CLEAN, split_documents=True)
                    docs = loader.load()
                
                # 为文档片段注入全息检索所需的元数据
                for doc in docs:
                    doc.metadata["collection_name"] = collection_name
                    doc.metadata["file_name"] = fname
                    # 分配唯一的父 ID，用于后续追溯原始内容
                    if not doc.metadata.get("parent_id"):
                        doc.metadata["parent_id"] = uuid.uuid4().hex
                
                all_docs.extend(docs)
                file_stats[fname] = len(docs)
                logger.info(f"从 {fname} 加载了 {len(docs)} 个片段")
            except Exception as e:
                logger.error(f"加载 {fp} 出错: {e}")

        if not all_docs:
            print("[RAG-Ingest] ! 警告: 未找到任何有效的文档内容。")
            return {"status": "warning", "message": "未找到需要摄入的文档内容。"}

        # 3. 知识精炼与增强
        if enable_qa:
            print(f"[RAG-Ingest] 正在启动 AI 全息知识增强 (LLM 精炼)...")
            all_docs = knowledge_refiner.refine_documents(all_docs)

        # 4. 写入向量存储
        print(f"[RAG-Ingest] 正在将最终生成的 {len(all_docs)} 个全息数据单元写入向量数据库 '{collection_name}'...")
        vector_store_service.add_documents(all_docs, collection_name=collection_name)
        
        print(f"[RAG-Ingest] <<< 摄入任务成功完成。")
        return {
            "status": "success", 
            "message": f"成功将 {len(all_docs)} 个片段摄入到 '{collection_name}'。",
            "chunk_count": len(all_docs),
            "file_stats": file_stats
        }

# 导出单例对象
ingestion_service = IngestionService()

def reset_collection(collection_name: str) -> dict:
    """
    重置集合：清空对应向量数据库中的所有数据。
    """
    from app.services.vector_store import vector_store_service
    success = vector_store_service.clear_collection(collection_name)
    if success:
        return {"status": "success", "message": f"知识库 '{collection_name}' 已成功重置。"}
    else:
        return {"status": "error", "message": f"重置知识库 '{collection_name}' 失败。"}
