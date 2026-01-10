RAG 系统全流程工作原理深度解析
本日志为您揭秘后台系统如何处理文档、生成知识以及响应搜索问答的完整生命周期。

1. 向量化触发阶段 (Ingestion Trigger)
触发时机：当您在“文件管理”界面点击“向量化”或“全库向量化”时。

调用路径：
前端: 
AiKnowledgeManager.tsx
 -> 调用 Java API /api/ai/knowledge/files/ingest。
Java 后端: 
RagService.java
 处理业务逻辑（更新数据库状态为 VECTORIZING），随后异步转发请求给 Python RAG 服务。
Python RAG: 
ingest.py
 路由接收请求，启动 ingestion_service.py。
2. 文档解析与切片逻辑 (Document Loading & Chunking)
详细过程：系统并不是简单地把文件存进去，而是经过了精细的预处理。

A. 多模型解析 (DocLoader.py)
格式识别: 根据后缀名自动选择加载器（PDF, Word, Excel, SQL, Markdown 等）。
智能 OCR: 如果 PDF 是扫描件（文字太少），会自动启动 RapidOCR 引擎进行图像识别。
LLM 清洗: 如果开启了 use_llm_clean，系统会调用 AI 纠正 OCR 过程中的错别字、去除页眉页脚乱码，确保存入的数据是高质量的。
B. 核心切片策略
父子文档架构:
父文档 (Parent): 保留文件的原始完整段落，存储在持久化数据库（Shelve）中。
子文档 (Child/Chunk): 使用 RecursiveCharacterTextSplitter 进行切分。
切片参数:
Chunk Size: 400 字符（确每个切片包含足够信息）。
Overlap: 50 字符（确保切片之间语义连贯，不丢失上下文）。
分隔符: ["\n\n", "\n", " ", ""] 按段落和句子尝试切分。
3. 全息知识增强 (Knowledge Enhancement)
触发时机：如果在向量化时勾选了“全息增加”（enable_qa）。

逻辑生成: 系统会调用 LLM (如 Qwen/OpenAI) 深入阅读每个段落，并生成：
语义切片 (_semantic): 原始文本的向量表达。
逻辑核 (_logic): 生成“这个段落能回答什么问题”，存储为问题向量，极大提升搜索准确率。
核心摘要 (_summary): 提取段落大意，用于全局搜索。
4. 实时问答检索流 (Q&A Retrieval)
触发时机：当您在“实验面板”输入问题并点击“检索”时。

混合检索过程 (
vector_store.py
)
多路并行搜索:
语义路: 寻找含义相近的内容。
关键词路 (BM25): 寻找包含特定专业术语的段落。
逻辑路: 匹配您的问题是否命中预先生成的“逻辑问题”。
多路加权合并:
不同的搜索路径有不同的权重（默认语义 0.6, 关键词 0.4 等）。
精排重测 (Rerank):
最终选出最相关的 Top N 个片段，再次调用 AI 模型进行“精准对齐”打分。
AI 答问
检索到的最相关的 N 个片段将作为“背景知识”注入到 Prompt 中：
“基于以下已知信息：[检索到的片段1, 片段2...]，请回答问题：[您的问题]”

AI 角色: 调用大模型根据上下文生成最终答案。
NOTE

总结：您的每次点击“检索”，其实都背后经历了：问题向量化 -> 四路混合搜索 -> 相似度加权 -> 后置精排 -> LLM 生成答案的复杂过程。

