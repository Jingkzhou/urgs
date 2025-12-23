# URGS-RAG: 智能监管知识库与检索服务

`urgs-rag` 是一个基于 FastAPI + LangChain 构建的检索增强生成 (RAG) 微服务，专为统一监管报送系统 (URGS) 提供智能化支持。它集成了多源数据录入、向量存储、语义检索以及 LLM 问答能力。

## 🧠 专业级知识工程架构 (Professional Architecture)

本项目采用了先进的 **Knowledge Refinery (知识精炼)** 架构，实现了从“存文档”到“存知识”的飞跃。

### 1. 核心流程
```mermaid
graph TD
    Raw[原始多模态数据] --> Loader[Loaders]
    Loader --> Cleaned[清洗后文本]
    
    subgraph Knowledge Refinery [知识精炼层]
        Cleaned --> Generator{LLM 生成器}
        Generator --> QA[Q&A 生成: 模拟用户提问]
        Generator --> Cleaned
    end
    
    subgraph Advanced Indexing [高级索引层]
        Cleaned --> ParentSplitter[Parent-Child 切分]
        ParentSplitter --> Parent[父文档 (完整上下文)]
        ParentSplitter --> Child[子向量 (精确匹配)]
        
        Parent --> Shelve[持久化存储 (Shelve)]
        Child --> VectorDB[向量数据库]
        Parent --> BM25[BM25 关键词索引]
    end
    
    UserQuery --> Hybrid{混合检索器}
    Hybrid -->|BM25 加权| BM25
    Hybrid -->|Vector 加权| VectorDB
    VectorDB -->|ID 映射| Parent
    BM25 -->|ID 映射| Parent
    Parent --> Answer[完整上下文答案]
```

### 2. 关键技术点

*   **知识精炼 (Refinery)**: 
    *   **Q&A 生成**: 自动为文档生成潜在问题（"存问题，找答案"），召回率提升 3倍。
    *   **智能清洗**: 利用 LLM 修复 OCR 错误、还原表格结构。
*   **父子索引 (Parent-Child)**: 
    *   **原理**: 搜索时匹配“小切片”以保证相关性，返回时提供“大父块”以保证上下文完整性。
    *   **优势**: 彻底解决 RAG 中“断章取义”的问题。
*   **混合检索 (Hybrid Search)**:
    *   **Vector**: 语义理解 (左脑)。
    *   **BM25**: 关键词匹配 (右脑)。
    *   **Ensemble**: 自动加权融合，既懂行话又懂逻辑。
*   **数据持久化**: 
    *   使用 `Shelve` 对父文档进行本地持久化存储，重启不丢失。

## 🚀 核心特性 (Core Features)

- **多源数据融合**:
  - **SQL**: 深度解析 SQL 逻辑。
  - **文档**: Word/PDF/Excel/TXT 全支持。
  - **资产**: API 自动拉取。
  - **血缘**: Neo4j 图谱对接。

- **智能化检索**:
  - **Hybrid Engine**: 向量 + 关键词双引擎。
  - **Auto Q&A**: 自动生成问答对索引。
  - **Context-Aware**: 返回完整的父文档上下文。

## 📂 项目结构

```
urgs-rag/
├── app/
│   ├── config.py            # 全局配置 (LLM, ChromaDB, 路径等)
│   ├── main.py              # FastAPI 入口
│   ├── loaders/             # 数据加载器 (多源异构)
│   │   ├── sql_loader.py    # SQL 文件加载与切分
│   │   ├── doc_loader.py    # 文档(PDF/Docx/Excel)与智能清洗
│   │   ├── asset_loader.py  # API 资产数据加载
│   │   └── lineage_loader.py # Neo4j 血缘数据加载
│   ├── services/            # 核心服务
│   │   ├── vector_store.py  # 向量库与混合检索 (Chroma + BM25 + Parent-Child)
│   │   ├── llm_chain.py     # LLM 基础服务 (数据清洗 / Q&A 生成)
│   │   └── refiner.py       # 知识精炼器 (New: 自动化 Q&A 增强)
│   ├── routers/             # API 路由
│   │   ├── ingest.py        # 数据录入接口
│   │   ├── query.py         # 检索接口
│   │   └── sql2text.py      # SQL 解释接口
│   └── prompts/             # Prompt 模板管理
└── requirements.txt         # 依赖列表
```

## 🛠️ 快速开始

### 1. 环境准备
- Python 3.10+
- Java 8+ (用于 GSP 解析，如果需要)
- Neo4j 数据库 (可选，用于血缘加载)

### 2. 安装依赖
由于部分 AI 依赖库对 Python 版本有特定要求，推荐使用我们提供的脚本自动创建环境（自动适配 Python 3.11）：
```bash
cd urgs-rag
chmod +x install_env.sh
./install_env.sh
source .venv/bin/activate
```

### 3. 配置
在 `app/config.py` 中配置环境变量，或使用 `.env` 文件：
- `CHROMA_PERSIST_DIRECTORY`: 向量库存放路径
- `LLM_API_BASE`: LLM 服务地址
- `NEO4J_URI` / `NEO4J_AUTH`: 图数据库连接信息

### 4. 初始化知识库 (数据录入)
将文档（PDF, Word, Excel, SQL 等）放入 `doc_store` 目录（系统会自动扫描该目录），然后运行自动化录入脚本：
```bash
python app/ingest_cli.py
```
> **注意**: 该过程包含 LLM 知识精炼（自动生成 Q&A），首次运行可能较慢，请耐心等待。此时会自动下载 Embedding 模型并建立本地向量索引。

### 5. 验证知识库内容
你可以使用我们提供的工具脚本来查看向量库的统计信息和抽样内容：
```bash
python inspect_vector_db.py
```
*输出示例：显示父文档总数、向量切片总数以及前 5 条数据的预览。*

### 6. 启动服务
```bash
uvicorn app.main:app --reload --host 0.0.0.0 --port 8001
```

## 🔌 API 接口说明

API 文档地址: `http://localhost:8001/doc`

### 1. 知识库录入 (Ingest)
触发数据加载与向量化。
- **POST** `/api/rag/ingest`
- **Body**:
  ```json
  {
      "type": "doc",
      "enable_qa_generation": true // 开启智能 Q&A 生成
  }
  ```

### 2. 语义检索 (Query)
仅检索相关文档片段，不经过 LLM。
- **POST** `/api/rag/query`
- **Body**:
  ```json
  {
      "query": "G01报表的统计范围是什么？",
      "k": 5
  }
  ```

### 3. SQL 解释 (SQL2Text)
结合知识库解释 SQL 逻辑。
- **POST** `/api/rag/explain`
- **Body**:
  ```json
  {
      "sql": "SELECT * FROM ..."
  }
  ```
