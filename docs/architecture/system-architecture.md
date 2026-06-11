# URGS 系统架构设计文档

> **URGS (Unified Resource Governance System)** — 企业级统一资源治理与调度系统
>
> 版本：v1.0 | 更新日期：2026-06-11

---

## 一、系统概述

URGS 是一个面向数据团队的综合性治理平台，整合了**任务调度、数据血缘治理、知识库检索（RAG）、元数据管理、版本发布**等核心能力，通过统一 Web 控制台提供可视化的运维监控与治理体验。

### 核心能力

| 能力域 | 说明 |
|--------|------|
| 任务调度 | 基于 Quartz 的分布式定时任务调度，支持任务依赖、日志追踪 |
| 数据血缘 | SQL 静态分析 + 运行时采集，构建表级/字段级血缘图谱 |
| 元数据管理 | 监管报表元数据注册、数据资产目录、数据源动态接入 |
| 知识库 RAG | 文档向量化检索、AI 对话助手、监管规则问答 |
| 版本管理 | Git 平台集成、生产包构建、发布流水线 |
| 运维监控 | 基础设施资产管理、Docker 容器监控、指标可视化 |
| 工作流 | 审批流程、任务协作、工单闭环 |

---

## 二、系统架构图

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           用户终端（Browser）                                │
│                    React 19 + Ant Design 6 + Vite 6                        │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               │ HTTPS / WebSocket (SSE)
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                        Nginx（可选反向代理）                                │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         urgs-api（Spring Boot 3）                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Controller│  │ Service  │  │Repository│  │  Quartz  │  │ WebSocket │  │
│  │  @RestController          │  │  调度层  │  │  SSE 推送 │  │
│  └─────┬────┘  └────┬─────┘  └────┬─────┘  └────┬─────┘  └─────┬─────┘  │
│        │             │              │              │               │        │
│  ┌─────▼────────────▼──────────────▼──────────────▼───────────────▼─────┐  │
│  │                     MyBatis-Plus / JPA                                │  │
│  └───────────────────────────────────────────────────────────────────────┘  │
└──────────────────────────────┬──────────────────────────────────────────────┘
                               ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                            数据存储层                                       │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │  MySQL   │  │  MongoDB │  │  Neo4j   │  │  Redis   │  │  Cassandra│  │
│  │  (主库)  │  │ (文档库) │  │ (血缘图) │  │  (缓存)  │  │  (时序)   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └───────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘
                               ▲
                               │
┌─────────────────────────────────────────────────────────────────────────────┐
│                        外部集成层                                           │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌───────────┐  │
│  │ Hive/    │  │  GitLab │  │  Dify    │  │  Docker  │  │  DataX    │  │
│  │ Hadoop   │  │ /GitHub │  │  (AI平台)│  │  Engine  │  │  (同步)   │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  └───────────┘  │
└─────────────────────────────────────────────────────────────────────────────┘

         ┌─────────────────────────────────────────┐
         │          独立部署服务                    │
         │  ┌──────────────┐  ┌────────────────┐  │
         │  │ urgs-executor│  │  urgs-agent    │  │
         │  │ (任务执行器)  │  │  (AI Agent 运行时)│
         │  └──────────────┘  └────────────────┘  │
         │  ┌──────────────────────────────────┐  │
         │  │  sql-lineage-engine (SQL 血缘引擎) │  │
         │  └──────────────────────────────────┘  │
         └─────────────────────────────────────────┘
```

---

## 三、模块详细说明

### 3.1 urgs-api（核心后端服务）

| 属性 | 值 |
|------|-----|
| 技术栈 | Spring Boot 3.2.4 + JDK 17 |
| ORM | MyBatis-Plus 3.5.6 + Spring Data JPA |
| 数据库迁移 | Flyway（V1 ~ V77） |
| 调度框架 | Spring Quartz |
| API 文档 | SpringDoc OpenAPI 2.5.0（Swagger UI） |

#### 包结构与职责

```
urgs-api/src/main/java/com/example/urgs_api/
│
├── ai/              # AI 功能：对话、Agent 管理、知识库
├── auth/            # 认证授权：JWT + RSA SSO
├── announcement/    # 公告管理
├── common/          # 公共组件、全局异常处理、统一响应
├── datasource/      # 动态数据源管理（支持多类型数据库）
├── im/              # 即时通讯（站内信）
├── knowledge/       # 知识库：文档上传、向量检索
├── metadata/        # 元数据：监管表注册、血缘分析
├── marketplace/     # 工作市场：需求、工单、KPI
├── metric/          # 指标管理：数据采集、图表配置
├── ops/             # 运维：Docker 管理、基础设施资产
├── org/             # 组织架构：部门、人员
├── permission/      # 权限：菜单、按钮级权限控制
├── quartz/          # 定时任务：任务定义、依赖、执行日志
├── role/            # 角色管理
├── sql/             # SQL 控制台：在线查询、结果导出
├── system/          # 系统配置、字典、参数
├── task/            # 任务管理：任务定义、实例、Runtime 监控
├── user/            # 用户管理
├── version/         # 版本管理：Git 浏览、生产包、Pipeline
└── workflow/        # 工作流引擎
```

#### 数据库支持

通过 `datasource` 模块动态接入多种数据库：

| 类型 | 驱动 |
|------|------|
| MySQL | mysql-connector-j |
| PostgreSQL | PostgreSQL JDBC |
| Oracle | Oracle JDBC |
| SQL Server | JTDS / Microsoft JDBC |
| DB2 | DB2 JDBC |
| ClickHouse | ClickHouse JDBC |
| Hive | Hive JDBC 3.1.3 |
| Inceptor | 自定义 JDBC 支持 |

---

### 3.2 urgs-web（前端应用）

| 属性 | 值 |
|------|-----|
| 框架 | React 19.2.0 |
| 构建工具 | Vite 6.2.0 |
| UI 组件库 | Ant Design 6.0.0 |
| 样式方案 | Tailwind CSS 3.4.13 |
| 路由 | React Router（Hash 模式） |
| 图表 | Recharts 3.5.0 + @antv/g6 5.1.1 |
| 流程图 | ReactFlow 11.11.4 + ELKjs |
| 编辑器 | Monaco Editor 0.55.1 + WangEditor 5 |
| Markdown | react-markdown + KaTeX + remark-math |

#### 前端目录结构

```
urgs-web/src/
├── api/              # 后端接口封装（按模块拆分）
├── components/       # 通用组件（表单、表格、图表）
├── pages/            # 页面组件（按业务模块组织）
│   ├── auth/         # 登录认证
│   ├── dashboard/    # 仪表盘
│   ├── metadata/     # 元数据管理
│   ├── lineage/      # 血缘图谱
│   ├── task/         # 任务管理
│   ├── quartz/       # 定时任务
│   ├── knowledge/    # 知识库
│   ├── ai/           # AI 助手
│   ├── version/      # 版本管理
│   ├── ops/          # 运维监控
│   └── system/       # 系统管理
├── hooks/            # 自定义 Hooks
├── types/            # TypeScript 类型定义
├── utils/            # 工具函数
├── store/            # 状态管理（如需要）
├── App.tsx           # 根组件（路由装配）
└── main.tsx          # 入口文件
```

---

### 3.3 urgs-executor（任务执行器）

独立部署的任务执行引擎，负责：

- 接收 `urgs-api` 下发的任务执行指令
- 执行 Shell 脚本、SQL 脚本、DataX 任务
- 通过 WebSocket / HTTP 回调汇报执行状态
- 支持多环境（Dev/Test/Prod）执行上下文

```
urgs-executor/
├── src/main/java/com/example/urgs_executor/
│   ├── controller/      # 接收执行请求
│   ├── service/         # 执行逻辑（Shell / SQL / DataX）
│   ├── callback/        # 执行结果回调 API
│   └── config/          # 执行环境配置
└── Dockerfile
```

---

### 3.4 urgs-agent（AI Agent 运行时）

Python 实现的 AI Agent 服务，提供：

- 与大模型（Dify 平台）的集成
- 知识库向量检索与 RAG 推理
- 监管规则智能问答
- Agent Skill 管理（App Code 模式）

```
urg-agent/
├── agent/              # Agent 核心逻辑
│   ├── rag/            # RAG 检索增强生成
│   ├── skill/          # Skill 加载与执行
│   └── llm/            # 大模型调用封装
├── api/                # FastAPI / Flask 接口层
├── config/             # 模型配置、知识库配置
└── requirements.txt
```

---

### 3.5 sql-lineage-engine（SQL 血缘分析引擎）

独立的 SQL 血缘解析引擎，支持：

- SQL 静态解析（基于 JSqlParser + 自定义语法扩展）
- 表级血缘：识别 `SELECT/JOIN/INSERT` 的源表与目标表
- 字段级血缘：追踪字段在 SQL 中的传递路径
- 多方言支持：MySQL、PostgreSQL、Hive、ClickHouse

```
sql-lineage-engine/
├── parser/             # SQL 解析器（JSqlParser 封装）
├── lineage/            # 血缘分析核心算法
│   ├── table_lineage.py    # 表级血缘
│   └── column_lineage.py   # 字段级血缘
├── models/             # 血缘关系数据模型
├── exporter/           # 导出到 Neo4j / JSON
└── tests/
```

---

## 四、核心数据流

### 4.1 任务调度数据流

```
User → urgs-web → urgs-api (QuartzController)
                              │
                              ▼
                        Quartz Scheduler
                              │ 触发
                              ▼
                    urgs-executor (远程执行)
                              │ 回调
                              ▼
                    urgs-api (ExecutorClientService)
                              │ 写入
                              ▼
                        MySQL (quartz_task_log)
                              │ 推送
                              ▼
                    urgs-web (SSE 实时日志)
```

### 4.2 SQL 血缘分析数据流

```
用户上传 SQL 脚本
        │
        ▼
urgs-api (LineageEngineController)
        │ 调用
        ▼
sql-lineage-engine (解析引擎)
        │ 输出血缘关系
        ▼
urgs-api (LineageService)
        │ 存储
        ├──► MySQL (lineage_analysis_record)
        └──► Neo4j (血缘图谱节点与边)
                    │ 查询
                    ▼
urgs-web (G6 图谱可视化)
```

### 4.3 AI 知识库问答数据流

```
用户提问（urgs-web 聊天界面）
        │
        ▼
urgs-api (AiChatController SSE 流式)
        │ 调用
        ▼
urgs-agent (Python 服务)
        │ 1. 向量检索（MongoDB 向量索引）
        │ 2. 召回相关文档片段
        │ 3. 拼装 Prompt
        ▼
Dify 平台（大模型推理）
        │ 流式返回
        ▼
urgs-web（Markdown 渲染 + KaTeX 公式）
```

### 4.4 版本发布数据流

```
Git Platform (GitLab/GitHub)
        │ OAuth 授权拉取
        ▼
urgs-api (GitPlatformService)
        │ 解析 Commit / Branch / Tag
        ▼
用户选择版本 → 创建 VersionPackage
        │
        ▼
urgs-api (PipelineController)
        │ 触发 CI/CD 流水线
        ▼
生产环境部署记录写入 MySQL
        │
        ▼
urgs-web（发布状态可视化）
```

---

## 五、数据模型核心实体

### 5.1 元数据与血缘

```
RegTable（监管报表）
  ├── id, cnName, enName, sourceSystem
  ├── fillFrequency, fillInstruction
  └── elements: RegElement（一对多）

RegElement（监管元素）
  ├── id, cnName, enName, dataType
  ├── desensitizeType, length
  └── regTableId（外键）

LineageAnalysisRecord（血缘分析记录）
  ├── id, sqlText, dataSourceType
  ├── analysisStatus, reviewStatus
  └── lineageEdges（JSON 存储血缘边）

LineageReview（血缘审核）
  ├── id, recordId, reviewerId
  ├── confirmedProblem, issuePending
  └── memory（审核备注）
```

### 5.2 任务与调度

```
QuartzTask（定时任务定义）
  ├── id, taskName, taskGroup, cronExpression
  ├── exePath, dataSourceId
  ├── dependentType, dependentTaskId
  └── status（ACTIVE/PAUSED）

QuartzTaskLog（任务执行日志）
  ├── id, taskId, triggerTime
  ├── executionStatus, output
  └── durationMs

TaskRealtimeMonitor（任务实时监测）
  ├── taskId, currentStatus
  └── lastHeartbeat
```

### 5.3 版本与发布

```
GitRepository（Git 仓库配置）
  ├── id, repoUrl, platformType
  ├── accessToken, createBy
  └── defaultBranch

VersionPackage（版本包）
  ├── id, packageNo, repoId
  ├── branch, commitHash
  ├── requirementNumber, envId
  └── deployStatus
```

---

## 六、技术选型总结

| 层级 | 技术 | 说明 |
|------|------|------|
| 前端框架 | React 19 + TypeScript | 函数式组件 + Hooks |
| 构建工具 | Vite 6 | 快速 HMR、按需加载 |
| UI 组件 | Ant Design 6 | 企业级组件库 |
| 样式 | Tailwind CSS 3 | 原子化 CSS |
| 图表 | Recharts + G6 | 常规图表 + 图谱可视化 |
| 后端框架 | Spring Boot 3.2 | Java 17、Jakarta EE 9+ |
| ORM | MyBatis-Plus + JPA | 灵活 SQL + 快速 CRUD |
| 数据库迁移 | Flyway | 版本化 Schema 管理 |
| 调度 | Quartz | 分布式定时任务 |
| 图数据库 | Neo4j | 血缘关系图存储 |
| 文档库 | MongoDB | 知识库文档存储 |
| 缓存 | Redis | 会话、热点数据 |
| 时序数据 | Cassandra | 指标时序存储 |
| 容器化 | Docker Compose | 本地开发与部署 |
| AI 集成 | Dify 平台 | 大模型推理 + RAG |

---

## 七、部署架构

```
┌──────────────────────────────────────────────────┐
│                  Docker Host                     │
│  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │
│  │ urgs-api │  │ urgs-web │  │ urgs-executor│  │
│  │ :8080    │  │ :3000    │  │ :8081        │  │
│  └────┬─────┘  └──────────┘  └──────┬───────┘  │
│       │                               │          │
│  ┌────▼───────────────────────────────▼───────┐  │
│  │         MySQL 8.0 / Redis / Neo4j          │  │
│  └──────────────────────────────────────────┘  │
│  ┌──────────────────┐  ┌─────────────────────┐ │
│  │  urgs-agent      │  │ sql-lineage-engine  │ │
│  │  (Python :8000)  │  │  (独立进程)          │ │
│  └──────────────────┘  └─────────────────────┘ │
└──────────────────────────────────────────────────┘
```

部署配置文件位于 `deploy/` 目录，包含：
- `docker-compose.yml` — 服务编排
- `.env.*` — 多环境配置模板
- `*.sh` — 部署脚本

---

## 八、安全设计

| 安全层 | 方案 |
|--------|------|
| 认证 | JWT Token + RSA SSO 单点登录 |
| 权限 | 菜单级 + 按钮级权限控制（RBAC） |
| 数据源 | 密码加密存储、连接池隔离 |
| SQL 安全 | MyBatis-Plus 参数绑定防注入 |
| API 安全 | Spring Security 全局拦截 |
| 文件上传 | 类型白名单、大小限制 |

---

## 九、扩展方向

1. **血缘分析增强**：引入运行时血缘采集（审计日志解析），与静态分析互补
2. **AI 能力深化**：支持更多大模型供应商、本地模型部署
3. **多租户隔离**：租户级数据源隔离、权限边界
4. **指标告警**：基于阈值触发的告警通知（企微/邮件/Webhook）
5. **OpenAPI 生态**：提供标准 REST API 供第三方系统集成

---

*本文档由 AI 辅助生成，基于项目代码分析。如有遗漏或错误，欢迎提交 PR 修正。*
