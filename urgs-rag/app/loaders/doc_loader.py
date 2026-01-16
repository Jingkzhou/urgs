import os
import glob
import shutil
import tempfile
import zipfile
import rarfile
import subprocess
from typing import List
import pandas as pd
from langchain_community.document_loaders import PyMuPDFLoader, Docx2txtLoader, TextLoader
from langchain_text_splitters import RecursiveCharacterTextSplitter
from langchain_core.documents import Document
from app.services.llm_chain import llm_service
from app.config import settings


class DocLoader:
    """
    文档加载器类，支持多种格式。
    
    功能包括：
    - 多种文件格式加载 (PDF, DOCX, TXT, Excel, ZIP, RAR)
    - 自动识别扫描版 PDF 并进行 OCR 处理
    - 递归解压并处理压缩包内容
    - 旧版 .doc 文件自动转换 (macOS 环境)
    - 文档内容 LLM 清理与精炼
    """

    def __init__(self, storage_path: str, use_llm_clean: bool = True, split_documents: bool = True):
        """
        初始化加载器。

        Args:
            storage_path (str): 文档存储路径（可以是目录或单个文件）。
            use_llm_clean (bool): 是否启用 LLM 进行文本清洗（纠正 OCR 错误、去除乱码等）。
            split_documents (bool): 是否在加载后自动进行文档切分。
        """
        self.storage_path = storage_path
        self.use_llm_clean = use_llm_clean
        self.split_documents = split_documents

    def load(self) -> List[Document]:
        """
        根据 storage_path 加载所有支持的文档。

        Returns:
            List[Document]: 加载并处理后的文档列表。
        """
        if not os.path.exists(self.storage_path):
            return []

        documents = []

        # 映射文件扩展名到对应的 LangChain 加载器类
        loaders_map = {
            ".docx": Docx2txtLoader,
            ".txt": TextLoader,
            ".py": TextLoader,
            ".md": TextLoader,
            ".sql": TextLoader,
        }

        # 确定待处理文件列表
        if os.path.isfile(self.storage_path):
            files_to_process = [self.storage_path]
        else:
            files_to_process = []
            for root, _, files in os.walk(self.storage_path):
                for file in files:
                    files_to_process.append(os.path.join(root, file))

        for file_path in files_to_process:
            ext = os.path.splitext(file_path)[1].lower()
            file_name = os.path.basename(file_path)

            try:
                docs = []
                # 1. 处理压缩包
                if ext in [".zip", ".rar"]:
                    docs = self._handle_archive(file_path, ext)
                # 2. 处理 PDF (包含 OCR 逻辑)
                elif ext == ".pdf":
                    docs = self._load_pdf_with_ocr_fallback(file_path)
                # 3. 处理常规文本/文档类
                elif ext in loaders_map:
                    loader_cls = loaders_map[ext]
                    loader = loader_cls(file_path)
                    docs = loader.load()
                # 4. 处理 Excel
                elif ext in [".xlsx", ".xls"]:
                    docs = self._load_excel(file_path)
                # 5. 处理旧版 Word (.doc)
                elif ext == ".doc":
                    docs = self._handle_doc_legacy(file_path)

                if docs:
                    # 补充元数据
                    for doc in docs:
                        if "source_type" not in doc.metadata:
                            doc.metadata["source_type"] = "document"
                        if "file_type" not in doc.metadata:
                            doc.metadata["file_type"] = ext
                        if "file_name" not in doc.metadata:
                            doc.metadata["file_name"] = file_name
                        if "original_file_path" not in doc.metadata:
                            doc.metadata["original_file_path"] = file_path

                        # 如果启用 LLM 清理，且不是压缩包内部文件（避免递归清理导致过慢），且符合清理启发式规则
                        is_from_archive = doc.metadata.get("is_from_archive", False)
                        if self.use_llm_clean and not is_from_archive and self._should_clean_text(doc.page_content, doc.metadata):
                            print(f"[DocLoader] >>> 正在使用 AI 清理文档文本噪声: {file_name}")
                            raw_text = doc.page_content
                            # 调用 LLM 服务清理文本
                            doc.page_content = llm_service.clean_text_with_llm(doc.page_content)
                            # 记录清理前后的样本（如果配置开启）
                            self._log_clean_sample(file_name, raw_text, doc.page_content)

                    documents.extend(docs)
                    if not is_from_archive:
                         print(f"[DocLoader] 成功从 {file_name} 中提取了 {len(docs)} 个原始段落单元")
            except Exception as e:
                print(f"加载文档出错 {file_path}: {e}")

        # 是否需要进行文档切分
        if self.split_documents:
            return self.split_documents_func(documents)
        return documents

    def _load_pdf_with_ocr_fallback(self, file_path: str) -> List[Document]:
        """
        加载 PDF，如果检测到是扫描件（文本太少），则回退到 OCR。
        """
        loader = PyMuPDFLoader(file_path)
        docs = loader.load()

        # 检查提取出的文本总量
        total_text = "".join([d.page_content for d in docs]).strip()
        if len(total_text) > 100:
            return docs

        print(f"检测到扫描版 PDF (文本长度 {len(total_text)})，触发 OCR 回退: {file_path}")

        ocr_docs = []
        try:
            import fitz
            from rapidocr_onnxruntime import RapidOCR
            from PIL import Image
            import numpy as np

            engine = RapidOCR()
            pdf_doc = fitz.open(file_path)

            for i, page in enumerate(pdf_doc):
                # 将 PDF 页面渲染为图像
                pix = page.get_pixmap()
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                # 执行 OCR
                result, _ = engine(np.array(img))

                page_text = ""
                if result:
                    page_text = "\n".join([line[1] for line in result])

                ocr_docs.append(
                    Document(
                        page_content=page_text,
                        metadata={"page": i, "source": file_path, "ocr_processed": True},
                    )
                )
            pdf_doc.close()
            return ocr_docs
        except ImportError:
            print("OCR 回退失败: rapidocr_onnxruntime 或 pymupdf 未安装。")
            return docs
        except Exception as e:
            print(f"OCR 处理过程中出错: {e}")
            return docs

    def _handle_archive(self, file_path: str, ext: str) -> List[Document]:
        """
        处理压缩包：解压到临时目录，并递归调用 DocLoader 加载。
        """
        docs = []
        temp_dir = tempfile.mkdtemp(prefix="urgs_rag_archive_")
        print(f"正在解压压缩包: {file_path} 到 {temp_dir}...")

        try:
            if ext == ".zip":
                with zipfile.ZipFile(file_path, "r") as zip_ref:
                    zip_ref.extractall(temp_dir)
            elif ext == ".rar":
                try:
                    with rarfile.RarFile(file_path) as rar_ref:
                        rar_ref.extractall(temp_dir)
                except rarfile.RarExecError:
                    print(f"警告: 未找到 'unrar' 命令。无法解压 RAR 文件: {file_path}")
                    return []
                except Exception as e:
                    print(f"解压 RAR 出错 {file_path}: {e}")
                    return []

            # 递归调用自身处理解压后的目录
            sub_loader = DocLoader(storage_path=temp_dir, use_llm_clean=self.use_llm_clean, split_documents=self.split_documents)
            sub_docs = sub_loader.load()

            for doc in sub_docs:
                doc.metadata["is_from_archive"] = True
                doc.metadata["archive_source"] = os.path.basename(file_path)

            docs.extend(sub_docs)
        except Exception as e:
            print(f"处理压缩包失败 {file_path}: {e}")
        finally:
            # 清理临时目录
            shutil.rmtree(temp_dir, ignore_errors=True)

        return docs

    def _load_excel(self, file_path: str) -> List[Document]:
        """
        加载 Excel 文件：将每个 Sheet 转换为 Markdown 表格格式。
        """
        documents = []
        try:
            xls = pd.ExcelFile(file_path)
            for sheet_name in xls.sheet_names:
                df = pd.read_excel(xls, sheet_name=sheet_name)

                text_content = []
                text_content.append(f"# Sheet: {sheet_name}")
                # 转换为 Markdown 表格，增强语义化
                markdown_table = df.to_markdown(index=False)
                text_content.append(markdown_table)

                full_text = "\n\n".join(text_content)
                if self.use_llm_clean:
                    print(f"正在使用 LLM 清理 Excel Sheet {sheet_name} ({os.path.basename(file_path)})...")
                    full_text = llm_service.clean_text_with_llm(full_text)

                documents.append(Document(page_content=full_text, metadata={"sheet_name": sheet_name}))
        except Exception as e:
            print(f"读取 Excel 出错 {file_path}: {e}")

        return documents

    def _handle_doc_legacy(self, file_path: str) -> List[Document]:
        """
        处理旧版 .doc 文件：使用 macOS 自带的 'textutil' 转换为 .docx 后加载。
        """
        docs = []
        temp_dir = tempfile.mkdtemp(prefix="urgs_doc_conv_")
        target_docx = os.path.join(temp_dir, os.path.basename(file_path) + "x")

        try:
            print(f"正在使用 textutil 转换旧版 .doc 为 .docx: {file_path}")
            result = subprocess.run(
                ["textutil", "-convert", "docx", "-output", target_docx, file_path],
                capture_output=True,
                text=True,
            )

            if result.returncode == 0 and os.path.exists(target_docx):
                loader = Docx2txtLoader(target_docx)
                docs = loader.load()
                for d in docs:
                    d.metadata["file_type"] = ".doc"
                    d.metadata["original_file_path"] = file_path
            else:
                print(f"textutil 转换失败 {file_path}: {result.stderr}")
        except Exception as e:
            print(f"转换旧版 doc 出错 {file_path}: {e}")
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)

        return docs

    def split_documents_func(self, documents: List[Document]) -> List[Document]:
        """
        文档切分：使用智能切片框架或递归字符切分器。
        """
        if settings.SMART_SPLITTER_ENABLED:
            from app.splitters.smart_splitter import smart_splitter
            print(f"[DocLoader] >>> 启动智能文档切片 (Smart Splitter)")
            chunks = smart_splitter.split_documents(documents)
            print(f"[DocLoader] 智能切片完成: 原始 {len(documents)} 段 -> 切分后 {len(chunks)} 片")
            return chunks
        
        chunk_size = 1000
        chunk_overlap = 200
        print(f"[DocLoader] >>> 启动文件切片 (Recursive): Size={chunk_size}, Overlap={chunk_overlap}")
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=chunk_size,
            chunk_overlap=chunk_overlap,
            separators=["\n\n", "\n", " ", ""],
        )
        chunks = splitter.split_documents(documents)
        print(f"[DocLoader] 切片完成: 原始 {len(documents)} 段 -> 切分后 {len(chunks)} 片")
        return chunks

    def _should_clean_text(self, text: str, metadata: dict) -> bool:
        """
        启发式算法：判断是否需要进行 LLM 文本清洗。
        
        基于配置、OCR 标志、以及不可见字符比例等进行判断。
        """
        if not text or len(text) < settings.CLEAN_TEXT_MIN_LENGTH:
            return False
        if not settings.ENABLE_LLM_CLEAN:
            return False
        if settings.CLEAN_OCR_ONLY and not metadata.get("ocr_processed"):
            return False
        if metadata.get("ocr_processed"):
            return True
        
        # 简单启发式：检查前 500 个字符中字母数字的比例
        alnum_count = sum(ch.isalnum() for ch in text[:500])
        ratio = alnum_count / max(len(text[:500]), 1)
        # 如果字母数字比例过低，可能是乱码或格式错误，建议清理
        return ratio < 0.6

    def _log_clean_sample(self, file_name: str, raw_text: str, cleaned_text: str) -> None:
        """
        记录清理样本以供后续评估清洗效果。
        """
        if not settings.CLEAN_SAMPLE_LOG:
            return
        try:
            os.makedirs(settings.CLEAN_SAMPLE_DIR, exist_ok=True)
            sample_path = os.path.join(settings.CLEAN_SAMPLE_DIR, f"{file_name}.txt")
            if os.path.exists(sample_path):
                return
            with open(sample_path, "w", encoding="utf-8") as f:
                f.write("[RAW]\n")
                f.write(raw_text[:2000])
                f.write("\n\n[CLEANED]\n")
                f.write(cleaned_text[:2000])
        except Exception:
            pass
