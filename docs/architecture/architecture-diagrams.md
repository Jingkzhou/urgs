# URGS 系统架构图（Mermaid）

> 使用 Mermaid 绘制，可在 GitHub、VS Code、Obsidian 等工具中直接渲染。

---

## 1. 系统总体架构

```mermaid
graph TB
    subgraph Client["客户端层"]
        Browser["浏览器<br/>React 19 + Ant Design 6"]
    end

    subgraph Gateway["接入层"]
        Nginx["Nginx（可选反向代理）"]
    end

    subgraph Backend["后端服务层 — urgs-api<br/>Spring Boot 3 + JDK 17"]
        Controller["Controller 层<br/>72个 REST 接口"]
        Service["Service 层<br/>业务逻辑"]
        Repo["数据访问层<br/>MyBatis-Plus + JPA"]
        Quartz["Quartz 调度器"]
        WS["WebSocket / SSE<br/>实时推送"]
        DynamicDS["动态数据源<br/>多类型数据库适配"]
    end

    subgraph Storage["数据存储层"]
        MySQL[("MySQL 8.0<br/>主库")]
        Mongo[("MongoDB<br/>文档/向量")]
        Neo4j[("Neo4j<br/>血缘图谱")]
        Redis[("Redis<br/>缓存/会话")]
        Cassandra[("Cassandra<br/>时序指标")]
    end

    subgraph External["外部集成"]
        Hive["Hive / Hadoop"]
        Git["GitLab / GitHub"]
        Dify["Dify AI 平台"]
        Docker["Docker Engine"]
        DataX["DataX 同步工具"]
    end

    subgraph Standalone["独立部署服务"]
        Executor["urgs-executor<br/>任务执行器"]
        Agent["urgs-agent<br/>Python AI Agent"]
        Lineage["sql-lineage-engine<br/>SQL 血缘引擎"]
    end

    Browser -->|"HTTPS / WebSocket"| Nginx
    Nginx --> Controller
    Controller --> Service
    Service --> Repo
    Service --> Quartz
    Service --> DynamicDS
    Controller --> WS
    Repo --> MySQL
    Repo --> Mongo
    Service -->|"写入图谱"| Neo4j
    Service -->|"缓存"| Redis
    Service -->|"时序写入"| Cassandra
    DynamicDS -->|"查询"| Hive
    Service -->|"Git 拉取"| Git
    Service -->|"AI 调用"| Agent
    Agent -->|"推理"| Dify
    Quartz -->|"下发任务"| Executor
    Service -->|"SQL 解析"| Lineage
```

---

## 2. 任务调度数据流

```mermaid
sequenceDiagram
    participant U as 用户（urgs-web）
    participant A as urgs-api
    participant Q as Quartz Scheduler
    participant E as urgs-executor
    participant DB as MySQL

    U->>A: 创建/触发定时任务
    A->>Q: 注册 Job / Trigger
    Q->>Q: Cron 触发
    Q->>E: HTTP 调用执行
    E->>E: 执行 Shell / SQL / DataX
    E->>A: 回调执行结果
    A->>DB: 写入 QuartzTaskLog
    A->>U: SSE 推送实时日志
```

---

## 3. SQL 血缘分析数据流

```mermaid
flowchart LR
    A["用户上传 SQL"] --> B["urgs-api<br/>LineageEngineController"]
    B --> C["sql-lineage-engine<br/>SQL 解析"]
    C --> D{"血缘类型"}
    D -->|"表级"| E["提取源表/目标表"]
    D -->|"字段级"| F["追踪字段传递路径"]
    E --> G["urgs-api<br/>LineageService"]
    F --> G
    G --> H[("MySQL<br/>lineage_analysis_record")]
    G --> I[("Neo4j<br/>血缘图谱")]
    I --> J["urgs-web<br/>G6 图谱可视化"]
    H --> K["urgs-web<br/>血缘审核界面"]
```

---

## 4. AI 知识库问答数据流

```mermaid
sequenceDiagram
    participant U as 用户
    participant W as urgs-web
    participant A as urgs-api<br/>AiChatController
    participant G as urgs-agent<br/>Python 服务
    participant V as MongoDB<br/>向量索引
    participant D as Dify 平台<br/>大模型

    U->>W: 输入提问
    W->>A: POST /api/ai/chat (SSE)
    A->>G: HTTP 调用 Agent
    G->>V: 向量相似度检索
    V-->>G: 召回相关文档片段
    G->>G: 拼装 RAG Prompt
    G->>D: 调用大模型推理
    D-->>G: 流式返回答案
    G-->>A: SSE 流式响应
    A-->>W: SSE 流式推送
    W-->>U: Markdown 渲染展示
```

---

## 5. 版本发布数据流

```mermaid
flowchart TD
    A["Git Platform<br/>GitLab / GitHub"] -->|"OAuth 拉取"| B["urgs-api<br/>GitPlatformService"]
    B --> C["解析 Branch / Commit / Tag"]
    C --> D["用户选择版本"]
    D --> E["创建 VersionPackage"]
    E --> F["urgs-api<br/>PipelineController"]
    F --> G["触发 CI/CD 流水线"]
    G --> H["部署到目标环境"]
    H --> I["写入部署记录"]
    I --> J["urgs-web<br/>发布状态可视化"]
```

---

## 6. 模块依赖关系

```mermaid
graph LR
    subgraph Frontend["前端 urgs-web"]
        Pages["Pages 页面"]
        API["API 封装层"]
        Comp["Components 组件"]
        Pages --> API
        Pages --> Comp
    end

    subgraph Core["urgs-api 核心模块"]
        Auth["auth<br/>认证"]
        Meta["metadata<br/>元数据"]
        Line["lineage<br/>血缘"]
        Task["task / quartz<br/>任务调度"]
        Know["knowledge / ai<br/>知识库/AI"]
        Ver["version<br/>版本管理"]
        Ops["ops<br/>运维"]
        Mkt["marketplace<br/>任务中心"]
    end

    Frontend -->|"REST / SSE"| Core

    Auth --> DB[(MySQL)]
    Meta --> DB
    Line --> DB
    Line --> Neo[(Neo4j)]
    Task --> DB
    Know --> Mongo[(MongoDB)]
    Know --> Agent["urgs-agent"]
    Ver --> DB
    Ops --> DB
    Mkt --> DB
```

---

## 7. 数据库 Schema 演进（Flyway 迁移）

```mermaid
graph LR
    V1["V1 Initial Schema<br/>基础表结构"]
    V13["V13 Knowledge Tables<br/>知识库表"]
    V20["V20 Lineage Record<br/>血缘分析记录"]
    V41["V41 Metric Tables<br/>指标管理"]
    V49["V49 Quartz Task Tables<br/>定时任务"]
    V54["V54 Lineage Review<br/>血缘审核"]
    V72["V72 Agent Build Mode<br/>Agent 构建模式"]
    V76["V76 Reg Asset Bindings<br/>资产物理绑定"]
    V77["V77 Infra System Manual<br/>基础设施手册"]

    V1 --> V13 --> V20 --> V41 --> V49 --> V54 --> V72 --> V76 --> V77
```

---

*以上图表使用 Mermaid 语法，在 GitHub README、VS Code 预览、Obsidian 等环境中可直接渲染。*
