# Dify DSL YAML 规范参考 (Node Schema Reference)

> 源自 Dify 官方源码 (`langgenius/dify`) 和已验证可导入的社区 YAML 模板。
> 版本适用范围：Dify 0.6 ~ 最新 (2026-02)。

---

## 1. 顶层结构 (Top-Level Structure)

一个有效的 Dify DSL 文件 **只有两个** 顶层 key：

```yaml
app:
  description: '应用简介'
  icon: "📖"
  icon_background: '#EFF1F5'
  mode: workflow          # 枚举值: workflow | chat | completion | agent-chat
  name: 应用名称
workflow:
  features: { ... }
  graph:
    edges: [ ... ]
    nodes: [ ... ]
    viewport:
      x: 0
      y: 0
      zoom: 1
```

### ⚠️ 关键易错点
- **不需要也不能有** `kind`、`version` 顶层字段。包含这些会导致部分版本的 Dify Cloud 前端解析失败白屏。
- `app.mode` **仅接受以下 4 个枚举值**：
  - `workflow`：非对话型工作流（API 入口 `/v1/workflows/run`）
  - `chat`：对话型 Chatflow（API 入口 `/v1/chat-messages`），支持 `sys.query`、`sys.conversation_history` 等系统变量
  - `completion`：基础文本补全应用
  - `agent-chat`：Agent 智能体应用
- ⛔ **`advanced-chat` 不是有效值！** 虽然 Dify UI 内部可能使用此术语描述 Chatflow，但在 DSL 导入时必须写 `chat`。写 `advanced-chat` 会导致前端白屏崩溃。

---

## 2. Features 结构 (features)

```yaml
workflow:
  features:
    file_upload:
      image:
        enabled: false
        number_limits: 3
        transfer_methods:
        - local_file
        - remote_url
    opening_statement: ''
    retriever_resource:
      enabled: false
    sensitive_word_avoidance:
      enabled: false
    speech_to_text:
      enabled: false
    suggested_questions: []
    suggested_questions_after_answer:
      enabled: false
    text_to_speech:
      enabled: false
      language: ''
      voice: ''
```

### ⚠️ 关键易错点
- `file_upload` 下**只有** `image` 子键（包含 `enabled`, `number_limits`, `transfer_methods`）。
- **不要加** `allowed_file_extensions`、`allowed_file_types`、`allowed_extensions` 等字段，这些在某些版本中不被识别会导致解析异常。
- ⛔ **features 子结构必须包含完整字段，不能省略任何属性**：
  - `file_upload.image` 必须同时包含 `enabled`、`number_limits`、`transfer_methods`
  - `text_to_speech` 必须同时包含 `enabled`、`language`、`voice`
  - 只写 `enabled: false` 而省略其他字段会导致 Dify 前端解析崩溃！

---

## 3. Node ID 规范

- Node ID 必须**使用毫秒级时间戳格式的纯数字字符串**，用单引号包裹。
- 示例：`'1720794829558'`、`'1720795610192'`
- **不要使用** `start_node`、`pm_node`、`end_node` 这种人类可读名称作为 ID。Dify 前端在渲染 React Flow 画布时，依赖数字 ID 做内部映射，非数字 ID 可能导致画布崩溃。

---

## 4. Edge 结构 (graph.edges)

```yaml
edges:
- data:
    isInIteration: false        # boolean
    sourceType: start           # 源节点 type（参见节点类型表）
    targetType: llm             # 目标节点 type
  id: '1720794829558-source-1720795218540-target'   # 格式：源ID-sourceHandle-目标ID-targetHandle
  source: '1720794829558'       # 源节点 ID
  sourceHandle: source          # 源句柄：'source'（标准）/'true'/'false'（if-else 分支）/'1'/'2' 等（分类器）
  target: '1720795218540'       # 目标节点 ID
  targetHandle: target          # 目标句柄：始终为 'target'
  type: custom                  # 始终为 'custom'
  zIndex: 0
```

### Edge ID 命名规则
格式为 `{sourceId}-{sourceHandle}-{targetId}-{targetHandle}`。
例如：`1720794829558-source-1720795218540-target`

### ⛔ Edge `sourceType` / `targetType` 一致性规则（极其重要）

Edge 中的 `sourceType` 和 `targetType` 必须与对应 Node 的 `data.type` 字段 **字符串完全一致**。

例如，如果一个节点的类型是 `knowledge-retrieval`，那么指向它的 Edge 必须写 `targetType: knowledge-retrieval`，从它出发的 Edge 必须写 `sourceType: knowledge-retrieval`。

**常见错误**：将一个 `code` 节点替换为 `knowledge-retrieval` 节点时，只改了 Node 的 `type` 而忘记同步修改 Edge 的 `sourceType` / `targetType`，导致 Dify 前端 React Flow 画布崩溃白屏。

> **自检规则**：生成 YAML 后，检查每条 Edge 的 `sourceType`/`targetType` 是否能在 `nodes` 列表中找到对应 `id` 的节点且 `type` 字段完全匹配。

---

## 5. Node 通用结构

每个 node 的外层结构完全一致：

```yaml
- data:
    desc: ''
    selected: false
    title: 节点标题
    type: start             # 节点类型枚举（见下方类型表）
    # ... 节点特定字段 ...
  height: 90                # 固定高度，不同类型值不同
  id: '1720794829558'       # 时间戳数字字符串
  position:
    x: 30
    y: 263
  positionAbsolute:
    x: 30
    y: 263
  selected: false
  sourcePosition: right
  targetPosition: left
  type: custom              # 始终为 'custom'
  width: 244                # 固定宽度，通常为 244
```

---

## 6. 所有节点类型枚举 (NodeType)

以下是从 Dify 源码 `core/workflow/enums.py` 提取的完整节点类型列表（`type` 字段的有效值）：

| NodeType 枚举值       | 中文名称     | 说明                           |
| :-------------------- | :----------- | :----------------------------- |
| `start`               | 开始         | 入口节点，定义用户输入变量     |
| `end`                 | 结束         | 终止节点，聚合输出变量         |
| `answer`              | 直接回复     | 仅 Chatflow 使用，直接返回消息 |
| `llm`                 | 大模型 (LLM) | 核心文本生成节点               |
| `knowledge-retrieval` | 知识检索     | RAG 检索                       |
| `if-else`             | 条件分支     | 路由逻辑                       |
| `code`                | 代码执行     | Python3 / NodeJS 脚本          |
| `template-transform`  | 模板转换     | Jinja2 模板                    |
| `question-classifier` | 问题分类器   | 按主题路由                     |
| `http-request`        | HTTP 请求    | 外部 API 调用                  |
| `tool`                | 工具         | 内置/自定义工具                |
| `variable-aggregator` | 变量聚合     | 合并多路径变量                 |
| `assigner`            | 变量赋值     | 显式变量写入                   |
| `iteration`           | 迭代         | 循环容器节点（⚠️ 不建议手写）   |
| `loop`                | 循环         | 新版循环容器                   |
| `parameter-extractor` | 参数提取     | 从文本提取结构化数据           |
| `document-extractor`  | 文档提取     | 从文件中提取文字               |
| `list-operator`       | 列表操作     | 列表过滤/排序                  |
| `agent`               | Agent        | 自主推理代理                   |

---

## 7. 常用节点 data 内部字段详解

### 7.1 Start (开始节点)

```yaml
data:
  desc: ''
  selected: false
  title: Start
  type: start
  variables:
  - label: input                # 显示名称
    max_length: 48              # 最大字符数
    options: []                 # select 类型时的选项
    required: true              # 是否必填
    type: text-input            # 类型枚举：text-input | paragraph | select | number
    variable: input             # 变量名（可在下游引用）
```

### 7.2 LLM (大模型节点)

```yaml
data:
  context:
    enabled: false
    variable_selector: []
  desc: ''
  model:
    completion_params:
      temperature: 0.7
    mode: chat
    name: gpt-4o               # 模型标识
    provider: openai            # 供应商标识
  prompt_template:
  - id: system_prompt_id        # 每条 prompt 的唯一 ID
```

#### ⛔ `completion_params` 白名单
`completion_params` 只能包含以下 Dify 标准参数：
- `temperature`、`top_p`、`max_tokens`、`presence_penalty`、`frequency_penalty`

**禁止添加** OpenAI 专属参数如 `response_format`、`seed`、`logprobs` 等。Dify 不识别这些参数，会导致应用异常。如果需要 JSON 输出，应通过 Prompt 指令要求大模型输出 JSON，而不是依赖 `response_format`。

```yaml
  prompt_template:
  - id: system_prompt_id        # 每条 prompt 的唯一 ID
    role: system                # system | user | assistant
    text: '你的系统提示词。引用变量使用 {{#NodeID.variable#}} 格式'
  selected: false
  title: LLM
  type: llm
  variables: []
  vision:
    enabled: false
```

### 引用变量语法
在 LLM 的 `prompt_template.text` 中引用上游节点的输出：
```
{{#1720794829558.input#}}         # 引用 Start 节点的 input 变量
{{#1720795218540.text#}}          # 引用上一个 LLM 节点的文本输出
```
格式为 `{{#节点ID.变量名#}}`。

### 7.3 End (结束节点)

```yaml
data:
  desc: ''
  outputs:
  - value_selector:
    - '1720802239924'           # 源节点 ID
    - text                      # 源变量名
    variable: output            # 输出变量名
  selected: false
  title: End
  type: end
```

### 7.4 Code (代码节点)

```yaml
data:
  code: |
    def main(arg1: str) -> dict:
        return {"result": arg1.upper()}
  code_language: python3        # python3 | javascript
  desc: ''
  outputs:
    result:
      type: string              # string | number | array[string] | object
  title: Code
  type: code
  variables:
  - value_selector:
    - '1720795218540'
    - text
    variable: arg1
```

### 7.5 If/Else (条件分支)

```yaml
data:
  conditions:
  - comparison_operator: contains
    id: condition_1
    value: 'keyword'
    variable_selector:
    - '1720795218540'
    - text
  desc: ''
  selected: false
  title: If/Else
  type: if-else
```
分支 Edge 的 `sourceHandle` 使用 `'true'` 或 `'false'`。

### 7.6 Template Transform (模板转换)

```yaml
data:
  desc: ''
  template: '检索结果: {{ arg1 }}'   # Jinja2 语法
  title: Template
  type: template-transform
  variables:
  - value_selector:
    - '1720800425522'
    - result
    variable: arg1
```

### 7.7 Knowledge Retrieval (知识检索节点)

```yaml
data:
  dataset_ids:
  - 'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx'   # 知识库 Dataset ID（环境绑定，导入后需手动关联）
  desc: ''
  query_variable:                             # 检索查询词的来源
  - '1720795218540'                           # 源节点 ID
  - text                                      # 源变量名
  retrieval_mode: multiple                    # 必填！枚举：single | multiple
  multiple_retrieval_config:                  # retrieval_mode 为 multiple 时必填
    reranking_enable: true
    reranking_mode: reranking_model
    reranking_model:
      model: bge-reranker-large
      provider: xinference
    top_k: 4
    score_threshold: 0.5
  selected: false
  title: 知识检索
  type: knowledge-retrieval
```

#### ❗️ 关键注意
- `dataset_ids` 是环境绑定的，导入后必须在 Dify 画布中手动关联知识库。生成 YAML 时可留空数组 `[]`。
- `retrieval_mode` 必须显式指定，缺少此字段会导致前端解析异常。
- 知识检索节点的输出变量名为 `result`，引用语法为 `{{#NodeID.result#}}`。

### 7.8 Answer (直接回复节点，仅 Chatflow)

```yaml
data:
  answer: '{{#1720800425522.output#}}'    # 引用上游节点的输出
  desc: ''
  selected: false
  title: 回复
  type: answer
```

#### ❗️ 关键注意
- `answer` 节点仅在 `app.mode: chat`（Chatflow）中使用。
- `app.mode: workflow` 中应使用 `end` 节点代替。
- 切勿混用：Chatflow 用 `answer`，Workflow 用 `end`。

---

## 8. 迭代节点注意事项

**⚠️ 强烈不建议手写 Iteration 节点的 YAML。**

Dify 的迭代 (Iteration) 节点在其内部维护了大量隐式的画布状态，包括内部子节点的嵌套坐标、循环控制的元数据映射等。这些信息几乎不可能通过手工 YAML 完美复现，且缺少任何一个字段都会导致 Dify React 前端白屏崩溃。

**推荐做法**：
1. 先生成不含迭代的基础工作流 YAML 并成功导入。
2. 在 Dify 的可视化编辑器中手动添加 Iteration 节点。
3. 将基础节点拖入 Iteration 框内并连线。
4. 如果想备份复杂工作流，使用 Dify 界面自带的"导出 DSL"功能。

---

## 9. 生成模板：最小可导入工作流

以下是**经过验证可成功导入**的最小工作流结构：

```yaml
app:
  description: ''
  icon: "🤖"
  icon_background: '#FFEAD5'
  mode: workflow
  name: 我的工作流
workflow:
  features:
    file_upload:
      image:
        enabled: false
        number_limits: 3
        transfer_methods:
        - local_file
        - remote_url
    opening_statement: ''
    retriever_resource:
      enabled: false
    sensitive_word_avoidance:
      enabled: false
    speech_to_text:
      enabled: false
    suggested_questions: []
    suggested_questions_after_answer:
      enabled: false
    text_to_speech:
      enabled: false
      language: ''
      voice: ''
  graph:
    edges:
    - data:
        isInIteration: false
        sourceType: start
        targetType: llm
      id: 1720794829558-source-1720795218540-target
      source: '1720794829558'
      sourceHandle: source
      target: '1720795218540'
      targetHandle: target
      type: custom
      zIndex: 0
    - data:
        isInIteration: false
        sourceType: llm
        targetType: end
      id: 1720795218540-source-1720795855124-target
      source: '1720795218540'
      sourceHandle: source
      target: '1720795855124'
      targetHandle: target
      type: custom
      zIndex: 0
    nodes:
    - data:
        desc: ''
        selected: false
        title: 开始
        type: start
        variables:
        - label: 用户输入
          max_length: 2000
          options: []
          required: true
          type: paragraph
          variable: input
      height: 90
      id: '1720794829558'
      position:
        x: 30
        y: 282
      positionAbsolute:
        x: 30
        y: 282
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 244
    - data:
        context:
          enabled: false
          variable_selector: []
        desc: ''
        model:
          completion_params:
            temperature: 0.7
          mode: chat
          name: gpt-3.5-turbo
          provider: openai
        prompt_template:
        - id: sys01
          role: system
          text: '你是一个AI助手。{{#1720794829558.input#}}'
        selected: false
        title: LLM
        type: llm
        variables: []
        vision:
          enabled: false
      height: 98
      id: '1720795218540'
      position:
        x: 334
        y: 282
      positionAbsolute:
        x: 334
        y: 282
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 244
    - data:
        desc: ''
        outputs:
        - value_selector:
          - '1720795218540'
          - text
          variable: output
        selected: false
        title: 结束
        type: end
      height: 90
      id: '1720795855124'
      position:
        x: 638
        y: 282
      positionAbsolute:
        x: 638
        y: 282
      selected: false
      sourcePosition: right
      targetPosition: left
      type: custom
      width: 244
    viewport:
      x: 0
      y: 0
      zoom: 1
```
