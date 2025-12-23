# Urgs Agent RAG System Flow

本文档详细描述了 Urgs 系统中 Agent 从前端交互到后端 API、RAG 服务再到向量数据库的完整调用链路。

## 1. 整体架构时序图 (Architecture Sequence)

```mermaid
sequenceDiagram
    participant User as 用户 (User)
    participant FE as 前端 (ArkPage.tsx)
    participant API as 后端 API (AiChatService)
    participant DB as 关系型数据库 (MySQL)
    participant RAG as RAG 服务 (QA Service)
    participant VS as 向量存储 (Vector Store)
    participant LLM as 大模型 (LLM)

    Note over User, FE: 1. 用户发送消息
    User->>FE: 输入问题并发送
    FE->>FE: 显示用户消息 (Optimistic UI)
    FE->>API: POST /chat/stream (SSE)

    Note over API, DB: 2. 后端会话处理
    API->>DB: 保存用户消息 (ai_chat_history)
    API->>API: 检查 Session 绑定的 Agent ID
    API->>DB: 获取 Agent 配置 (System Prompt, KB ID)

    Note over API, RAG: 3. RAG 检索增强 (核心链路)
    alt Agent 绑定了知识库
        API->>RAG: POST /qa (Query, CollectionNames)
        RAG->>VS: 混合检索 (Hybrid Search)
        par 并行检索
            VS->>VS: 语义检索 (Semantic Path)
            VS->>VS: 逻辑检索 (Logic Path)
            VS->>VS: 关键词检索 (BM25)
        end
        VS->>VS: 加权融合 (Ensemble Weights)
        VS-->>RAG: 返回 Top-K 文档 (Docs)
        RAG-->>API: 返回 {answer="Retrieval Only", sources=[...]}
        
        API->>FE: SSE event: "sources" (推送参考资料)
        FE->>FE: 展示“发现的参考资料”折叠面板
    end

    Note over API, LLM: 4. 上下文构建与生成
    API->>API: 压缩历史上下文 (Adaptive Summarization)
    API->>API: 构建 Prompt (System + Context + Query)
    API->>LLM: Stream Chat Completion
    
    loop 流式生成
        LLM-->>API: Chunk (Token)
        API-->>FE: SSE event: message (Token)
        FE->>FE: 实时打字机效果 & 智能跟随滚动
    end

    LLM-->>API: [DONE]
    API->>DB: 保存 AI 回复
    API-->>FE: SSE event: [DONE]
```

## 2. 详细代码链路分析 (Code Walkthrough)

### 第一阶段：前端交互 (Frontend)
- **文件**: `urgs-web/src/components/ark/ArkPage.tsx`
- **动作**: 用户点击发送。
- **关键逻辑**:
    - `handleSubmit`: 创建临时的 User 和 Assistant 消息对象。
    - `streamChatResponse`: 发起 SSE 请求，监听 `onChunk` (内容) 和 `onSources` (RAG 源)。
    - **UI 特效**: 利用 `messagesEndRef` 和 `isAtBottom` 实现智能跟随滚动。

### 第二阶段：后端编排 (Backend API)
- **文件**: `urgs-api/.../ai/service/AiChatServiceImpl.java`
- **方法**: `streamChatWithPersistence`
- **关键逻辑**:
    1.  **Agent 识别**: 根据 `sessionId` 查找 `Agent` 配置。
    2.  **RAG 触发**: 如果 Agent 配置了 `KnowledgeBase`，调用 `ragService.query()`。
    3.  **源推送**: 收到 RAG 结果后，通过 `emitter.send(event().name("sources")...)` 立即推送到前端，让用户在等待生成时就能看到参考资料。
    4.  **上下文组装**: 将 RAG 返回的文本追加到 `userPrompt` 中，形成增强的 Prompt。
    5.  **LLM 生成**: 调用大模型进行流式回答。

### 第三阶段：RAG 服务 (Python Service)
- **文件**: `urgs-rag/app/services/qa_service.py`
- **方法**: `answer_question`
- **关键逻辑**:
    - 接收 Java 端的 `ragReq` (Query, CollectionNames)。
    - 调用 `vector_store_service.similarity_search`。
    - **优化点**: 此处不再调用 LLM 生成，仅返回检索结果 (`answer="Retrieval Only"`)，大幅降低延迟。

### 第四阶段：向量检索 (Vector Store)
- **文件**: `urgs-rag/app/services/vector_store.py`
- **方法**: `similarity_search` -> `ensemble_retriever`
- **关键逻辑 (混合检索策略)**:
    - **BM25 (40%)**: 关键词匹配，确保专有名词（如系统代码、特定术语）由于精确匹配而被召回。
    - **Semantic (30%)**: 向量语义匹配，理解问题的意图（Path 1: 语义路径）。
    - **Logic (30%)**: 逻辑推导匹配（Path 2: 逻辑/范式路径）。
    - **Top-K**: 最终返回前 10 个最相关的**父文档** (Parent Document) 给后端。
