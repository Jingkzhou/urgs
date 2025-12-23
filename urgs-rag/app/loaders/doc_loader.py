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

class DocLoader:
    def __init__(self, storage_path: str, use_llm_clean: bool = True):
        self.storage_path = storage_path
        # If storage_path is a file, treat it as a directory containing just that file effectively, 
        # or handle single file loading. But typically we pass a directory.
        self.use_llm_clean = use_llm_clean

    def load(self) -> List[Document]:
        """
        Load PDF, DOCX, TXT, Excel, ZIP, RAR documents from directory.
        """
        if not os.path.exists(self.storage_path):
            return []

        documents = []
        
        # Loaders map (standard text file types)
        loaders_map = {
            ".docx": Docx2txtLoader,
            ".txt": TextLoader,
            ".py": TextLoader, 
            ".md": TextLoader,
            ".sql": TextLoader
        }

        # Recursively find files
        # Check if single file
        if os.path.isfile(self.storage_path):
            files_to_process = [self.storage_path]
            root_dir = os.path.dirname(self.storage_path)
        else:
            files_to_process = []
            root_dir = self.storage_path
            for root, _, files in os.walk(self.storage_path):
                for file in files:
                    files_to_process.append(os.path.join(root, file))

        for file_path in files_to_process:
            ext = os.path.splitext(file_path)[1].lower()
            file_name = os.path.basename(file_path)
            
            try:
                docs = []
                # 1. Handle Archives (ZIP/RAR)
                if ext in [".zip", ".rar"]:
                    docs = self._handle_archive(file_path, ext)

                # 2. Handle PDF with OCR Fallback
                elif ext == ".pdf":
                    docs = self._load_pdf_with_ocr_fallback(file_path)

                # 3. Handle Standard Text Files
                elif ext in loaders_map:
                    loader_cls = loaders_map[ext]
                    loader = loader_cls(file_path)
                    docs = loader.load()
                
                # 3. Handle Excel Files
                elif ext in [".xlsx", ".xls"]:
                    docs = self._load_excel(file_path)
                
                # 4. Handle Legacy Word (.doc) Files
                elif ext == ".doc":
                    docs = self._handle_doc_legacy(file_path)

                # Enhance Metadata & Optional Cleaning
                if docs:
                    for doc in docs:
                        # Improve metadata, preserve original source if not already set (recursively)
                        if "source_type" not in doc.metadata:
                            doc.metadata["source_type"] = "document"
                        if "file_type" not in doc.metadata:
                            doc.metadata["file_type"] = ext
                        if "file_name" not in doc.metadata:
                            doc.metadata["file_name"] = file_name
                        if "original_file_path" not in doc.metadata:
                            doc.metadata["original_file_path"] = file_path
                        
                        # LLM Cleaning Step (Skip for archive chunks already cleaned recursively, but here we iterate flat)
                        # Note: Recursive DocLoader instances will have use_llm_clean=True propagated.
                        # So we only clean if this DocLoader instance loaded it directly.
                        # Actually, _handle_archive calls new DocLoader w/ use_llm_clean. 
                        # So docs returned from _handle_archive are already cleaned.
                        # We only clean if NOT from archive (check metadata source?)
                        
                        # Simple logic: If we just loaded it (standard/excel), clean it.
                        # If it came from archive, it's already cleaned.
                        is_from_archive = doc.metadata.get("is_from_archive", False)
                        
                        if self.use_llm_clean and not is_from_archive:
                             # Clean
                             # print(f"Cleaning document {file_name} with LLM...")
                             # doc.page_content = llm_service.clean_text_with_llm(doc.page_content)
                             # Optimization: Only clean if it looks "messy" or is OCR'd PDF.
                             pass 
                             # For now disable double cleaning logic or keep it simple.
                             # Let's keep cleaning inside specific loaders or just here.
                             # To avoid double cleaning, let's assume `_handle_archive` returns cleaned docs.
                    
                    documents.extend(docs)

            except Exception as e:
                print(f"Error loading document {file_path}: {e}")

        return self.split_documents(documents)

    def _load_pdf_with_ocr_fallback(self, file_path: str) -> List[Document]:
        """
        Load PDF and fallback to OCR if it's a scanned document.
        """
        loader = PyMuPDFLoader(file_path)
        docs = loader.load()
        
        # Check if text is too short (likely scanned PDF)
        total_text = "".join([d.page_content for d in docs]).strip()
        if len(total_text) > 100:
            return docs
            
        print(f"Detected scanned PDF (text length {len(total_text)}), triggering OCR fallback: {file_path}")
        
        ocr_docs = []
        try:
            import fitz
            from rapidocr_onnxruntime import RapidOCR
            from PIL import Image
            import numpy as np
            
            engine = RapidOCR()
            pdf_doc = fitz.open(file_path)
            
            for i, page in enumerate(pdf_doc):
                pix = page.get_pixmap()
                img = Image.frombytes("RGB", [pix.width, pix.height], pix.samples)
                result, _ = engine(np.array(img))
                
                page_text = ""
                if result:
                    page_text = "\n".join([line[1] for line in result])
                
                ocr_docs.append(Document(
                    page_content=page_text,
                    metadata={
                        "page": i,
                        "source": file_path,
                        "ocr_processed": True
                    }
                ))
            pdf_doc.close()
            return ocr_docs
        except ImportError:
            print("OCR fallback failed: rapidocr_onnxruntime or pymupdf not installed.")
            return docs
        except Exception as e:
            print(f"Error during OCR processing: {e}")
            return docs

    def _handle_archive(self, file_path: str, ext: str) -> List[Document]:
        """
        Extract archive to temp dir and load recursively.
        """
        docs = []
        temp_dir = tempfile.mkdtemp(prefix="urgs_rag_archive_")
        print(f"Extracting archive: {file_path} to {temp_dir}...")
        
        try:
            if ext == ".zip":
                with zipfile.ZipFile(file_path, 'r') as zip_ref:
                    zip_ref.extractall(temp_dir)
            elif ext == ".rar":
                try:
                    with rarfile.RarFile(file_path) as rar_ref:
                        rar_ref.extractall(temp_dir)
                except rarfile.RarExecError:
                    print(f"Warning: 'unrar' not found. Cannot extract RAR file: {file_path}")
                    return []
                except Exception as e:
                    print(f"Error extracting RAR {file_path}: {e}")
                    return []

            # Recursively load from temp dir
            # Propagate settings
            sub_loader = DocLoader(storage_path=temp_dir, use_llm_clean=self.use_llm_clean)
            sub_docs = sub_loader.load()
            
            # Tag docs as from this archive
            for doc in sub_docs:
                doc.metadata["is_from_archive"] = True
                doc.metadata["archive_source"] = os.path.basename(file_path)
            
            docs.extend(sub_docs)
            
        except Exception as e:
            print(f"Failed to process archive {file_path}: {e}")
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
            
        return docs

    def _load_excel(self, file_path: str) -> List[Document]:
        """
        Load Excel file and convert rows to semantic text.
        """
        documents = []
        try:
            # Read all sheets
            xls = pd.ExcelFile(file_path)
            for sheet_name in xls.sheet_names:
                df = pd.read_excel(xls, sheet_name=sheet_name)
                
                # Convert each row to a markdown row or sentence
                text_content = []
                text_content.append(f"# Sheet: {sheet_name}")
                
                # Convert dataframe to markdown table
                # LLM handles markdown tables well
                markdown_table = df.to_markdown(index=False)
                text_content.append(markdown_table)
                
                # Create a document per sheet (or split later)
                full_text = "\n\n".join(text_content)
                
                if self.use_llm_clean:
                     print(f"Cleaning Excel sheet {sheet_name} in {os.path.basename(file_path)}...")
                     full_text = llm_service.clean_text_with_llm(full_text)

                documents.append(Document(page_content=full_text, metadata={"sheet_name": sheet_name}))
                
        except Exception as e:
             print(f"Error reading Excel {file_path}: {e}")
        
        return documents

    def _handle_doc_legacy(self, file_path: str) -> List[Document]:
        """
        Convert legacy .doc to .docx using macOS 'textutil' and load it.
        """
        docs = []
        # Create a temporary directory for the conversion
        temp_dir = tempfile.mkdtemp(prefix="urgs_doc_conv_")
        target_docx = os.path.join(temp_dir, os.path.basename(file_path) + "x")
        
        try:
            print(f"Converting legacy .doc to .docx using textutil: {file_path}")
            # textutil -convert docx -output target_docx source_file
            result = subprocess.run([
                "textutil", "-convert", "docx", 
                "-output", target_docx, 
                file_path
            ], capture_output=True, text=True)
            
            if result.returncode == 0 and os.path.exists(target_docx):
                loader = Docx2txtLoader(target_docx)
                docs = loader.load()
                # Restore original file_path in metadata
                for d in docs:
                    d.metadata["file_type"] = ".doc"
                    d.metadata["original_file_path"] = file_path
            else:
                print(f"textutil conversion failed for {file_path}: {result.stderr}")
        except Exception as e:
            print(f"Error handling legacy doc {file_path}: {e}")
        finally:
            shutil.rmtree(temp_dir, ignore_errors=True)
            
        return docs

    def split_documents(self, documents: List[Document]) -> List[Document]:
        """
        Split text documents.
        """
        splitter = RecursiveCharacterTextSplitter(
            chunk_size=1000,
            chunk_overlap=200,
            separators=["\n\n", "\n", " ", ""]
        )
        return splitter.split_documents(documents)
