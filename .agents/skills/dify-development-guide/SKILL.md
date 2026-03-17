---
name: dify-developer-guide
description: 专门用于指导开发者如何在 Dify (开源 LLM 应用开发平台) 上创建、配置、开发及编排大模型应用的工作指南。当用户提出类似“如何在 Dify 开发工作流”、“帮我写一个 Dify 应用”或“Dify 的 Agent 怎么弄”等需求时触发。
---

# Dify 应用开发全景指南 (Dify Developer Guide)

此技能用于帮助开发者快速、规范地在 Dify 平台上构建不同类型的应用（Prompt/Agent/Workflow）。Dify 是一个极简易用的 LLM 应用开发平台，它的核心是将繁琐的 Prompt 工程、RAG 检索和系统工具调用通过所见即所得的界面与 DSL 文件来管理。

## 1. 核心应用类型解析 (分类选型)

当接收到开发需求时，**第一步一定是帮助用户确定应用类型**：

| 应用类型                       | 适用场景                                                                                                     | 开发特征                                                                       | 导出格式 |
| :----------------------------- | :----------------------------------------------------------------------------------------------------------- | :----------------------------------------------------------------------------- | :------- |
| **基础助手 (Basic Assistant)** | 简单的问答、翻译、文档总结。固定单轮或多轮对话。                                                             | 纯 Prompt 工程，配置简单，可挂载少量上下文。                                   | `.yml`   |
| **智能体 (Agent)**             | 具有自主推理能力，需要让大模型自己决定“何时使用什么工具”。适用于复杂任务如“帮我查一下今天的天气并写一首诗”。 | 依赖强大的推理模型（如 GPT-4 / Claude-3.5），需要配置一系列 Tools 给模型调用。 | `.yml`   |
| **工作流 (Workflow/Chatflow)** | 业务逻辑极度固定，不允许模型发散。典型的 SOP 流程，如“第一步翻译 -> 第二步提取实体 -> 第三步存入数据库”。    | 拖拽式节点连线，包含条件分支 (If/Else)、代码节点 (Python/Nodejs)、迭代循环。   | `.yml`   |

*注意：如果需要带聊天上下文记忆的工作流，请使用 `Chatflow`；如果是一次性运行（例如后台定时处理任务），请使用 `Workflow`。*

---

## 2. Dify 开发工作流 (如何帮助用户构建)

作为系统开发向导，你需要遵循以下步骤来协助用户开发：

### 步骤 A: 需求拆解与架构设计
- 询问用户应用的核心目的、输入输出参数。
- 确认是否需要挂载外部知识库 (RAG)。
- 确认是否需要调用外部接口 (HTTP Request) 或是手写代码逻辑 (Code Node)。

### 步骤 B: 编写并提供 DSL (YAML)
你可以直接为用户生成符合 Dify 结构的 `.yml` 文件（**首选**）。
Dify 的工作流只有 `app` 和 `workflow` 两个顶层 key，由 `graph.nodes`, `graph.edges` 等核心节点组成。**禁止添加 `kind`、`version` 等额外顶层字段。**
- 生成规范的 YAML 时，务必确保 `id` 唯一。
- **示例：引导用户怎么用**：明确告诉用户将此 YAML 存为文件，并在 Dify 控制台点击“导入 (Import)”。

### 步骤 C: 引导纯代码集成 (如果用户选择 API 方案)
如果用户不希望在 Dify UI 上操作，希望将 Dify 能力集成到 Java / Python 后端：
- 使用 `Dify API Key` 进行标准 RESTful 调用。
- **Chat Messages API**：`POST /v1/chat-messages` (支持 SSE 流式返回，需携带 `query`, `user` 和可选的 `conversation_id`)。
- **Workflows API**：`POST /v1/workflows/run` (只需传入 `inputs` 字典)。

---

## 3. Dify 核心节点编写模式 (Workflow/Chatflow)

如果用户要求你**规划工作流**，你需要了解 Dify 常见 Node 类型以便在 YAML 或者语言描述中准确使用：

1. **Start (开始节点)**：定义用户必填的表单参数 (`variables`)。
2. **LLM (大模型节点)**：最核心的文本生成节点。包括 System Prompt、Model 选择。支持引用前序节点的内容 (`{{#NodeID.text#}}`)。
3. **Knowledge Retrieval (知识检索)**：RAG 节点，连接 Dify 的 Dataset。
4. **Code (代码节点)**：允许编写 Python 3 / Node.js 脚本处理杂七杂八的格式化数据。
5. **If/Else (条件分支)**：根据前序节点的输出决定走哪条路。
6. **End (结束节点)**：聚合所有输出，返回给客户端。

---

## 4. Dify 开发最佳实践 & 避坑指南

- **RAG 召回问题**：经常遇到 RAG 查不到东西。指导用户检查 Dify Dataset 的**分块策略**（Chunk Size）以及**检索模式**（建议开启混合检索 Hybrid Search + Rerank）。
- **工具调用失败或死循环**：在 Agent 模式下，如果发现大模型不断调用错误工具，指导用户在“工具配置”中**写清楚详尽的 Tool Description**。大模型是靠 Description 来决定用不用这个参数的。
- **提示词过长**：在 Workflow 中，如果前序节点的输出过长，放入下一个 LLM 节点极易触发 Token 超限。建议中间加一个 Code Node 进行裁剪，或者直接使用总结节点。

---

## 5. DSL 规范参考（⚠️ 生成 YAML 前必须查阅）

在为用户生成 Dify DSL YAML 文件前，**必须先阅读** [DSL 节点规范参考](references/dsl-node-schema.md)。
该文档包含从 Dify 源码中提取的精确字段定义、已验证可导入的模板、以及常见导致导入失败的易错点。

### 核心规则速查
1. **顶层结构**：只有 `app` + `workflow` 两个 key，禁止加 `kind`、`version`。
2. **`app.mode` 枚举**：只允许 `workflow` | `chat` | `completion` | `agent-chat`。**禁止使用** `advanced-chat` 等非标准值，否则前端白屏崩溃。
3. **Node ID**：必须使用毫秒时间戳格式的纯数字字符串，如 `'1720794829558'`。
4. **Edge `sourceType` / `targetType` 一致性**：必须与对应 Node 的 `data.type` **完全一致**。例如 `knowledge-retrieval` 节点的 Edge 必须写 `sourceType: knowledge-retrieval`，不能写 `code` 或其他简称。**这是最常见的导入崩溃原因之一。**
5. **Edge ID**：格式为 `{sourceId}-{sourceHandle}-{targetId}-{targetHandle}`。
6. **features 属性完整性**：`features` 下所有子结构必须包含完整字段，不能省略。`file_upload.image` 必须含 `enabled`、`number_limits`、`transfer_methods`；`text_to_speech` 必须含 `enabled`、`language`、`voice`。
7. **`completion_params` 白名单**：只能含 Dify 标准参数（`temperature`、`top_p`、`max_tokens`、`presence_penalty`、`frequency_penalty`）。**禁止** OpenAI 专属参数如 `response_format`、`seed`。
8. **`knowledge-retrieval` 必填字段**：`dataset_ids`（数组）、`query_variable`（变量选择器）、`retrieval_mode`（`single` | `multiple`）。`multiple` 模式还须含 `multiple_retrieval_config`。
9. **Iteration 节点**：不要手写，必须在 Dify UI 上拖拽生成。
10. **变量引用语法**：`{{#NodeID.variable#}}`。

---

## 🎯 触发话术模板
如果检测到用户想开发 Dify 应用，你可以主动使用这样的结构回答：
1. "我理解你需要一个具有 XXX 功能的 Dify 应用。根据需求，我建议采用 【Chatflow 工作流 / Agent 智能体】 的模式。"
2. "我可以为你生成一份**现成的 YAML 配置文件**，你直接导入 Dify 即可；或者我可以帮你**手写梳理每个业务节点的逻辑**。"
3. [输出具体的业务逻辑拆解 / YAML 代码]
