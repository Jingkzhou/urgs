# URGS 智能任务分发与多 Agent 协作三期建设计划

## 1. 背景与目标

URGS 当前已经具备 ARK 对话入口、Agent 配置、RAG、Dify、Agent App、DeepAgents 微服务等基础能力。下一阶段目标不是简单增加更多 Agent，而是构建一套可控、可审计、可扩展的智能任务分发架构，让用户在 ARK 中发起任务后，系统可以自动识别意图、选择专家 Agent、编排多步骤任务、展示执行过程，并输出可追踪的最终结果。

本计划参考以下竞品/框架模式：

- LangChain / LangGraph: Router、Subagents、Handoffs、Skills、Custom workflow 混合模式。
- OpenAI Agents SDK: handoff、guardrails、tracing 的生产化思路。
- CrewAI: Flow 管流程和状态，Crew/Agent 负责智能执行。
- AutoGen: 事件驱动、多 Agent runtime、分布式扩展能力。

URGS 采用的核心原则：

- 中心调度优先，不做完全去中心化 Agent 互相聊天。
- `urgs-api` 作为 Agent Gateway，负责鉴权、权限、审计、会话和 SSE 转发。
- `urgs-deepagents` 作为 DeepAgents Runtime，负责专家 Agent 执行。
- Agent 能力通过 Registry、Memory、Skills、Tools、Policy 组合定义。
- 所有任务分发、工具调用、handoff、模型输出必须可追踪、可回放。
- 默认最小权限：文件写入、命令执行、敏感数据读取必须显式授权。

## 2. 目标架构

```text
ARK 前端
  |
  v
urgs-api / Agent Gateway
  |
  +--> Router 智能分发器
  |
  +--> Planner / Supervisor
  |
  +--> Tool Gateway
  |
  +--> Run / Trace / Audit
  |
  v
urgs-deepagents / DeepAgents Runtime
  |
  +--> general-agent
  +--> metadata-agent
  +--> lineage-agent
  +--> sql-review-agent
  +--> ops-agent
  +--> code-readonly-agent
  +--> report-agent
  +--> evaluator-agent
```

推荐执行模式：

```text
普通问题:
Router -> 单 Agent -> 返回

复杂问题:
Router -> Planner -> 多 Agent 串行/并行 -> Synthesizer -> Evaluator -> 返回

连续专业对话:
Router -> Handoff 到专家 Agent -> 后续多轮保持 active agent

后台长任务:
Router -> Planner -> Async Job -> 前端订阅进度 -> 完成后汇总
```

## 3. 一期：任务分发基础设施与单 Agent 可控执行

### 3.1 建设目标

先把“智能分发”的基础打牢：统一 Agent Registry、Router MVP、DeepAgents memory/skills 配置、运行事件落库、前端过程展示。第一期不追求复杂多 Agent 协作，重点是让系统可以稳定地把任务路由到一个正确 Agent，并完整记录过程。

### 3.2 主要交付

1. Agent Registry 数据模型

   建议新增或扩展字段：

   ```text
   agent_code
   agent_name
   agent_type
   build_mode
   description
   capability_tags
   routing_examples
   memory_files
   skill_dirs
   tool_allowlist
   policy_config
   model_config
   status
   sort_order
   ```

2. DeepAgents 配置能力

   支持平台级和 Agent 级配置：

   ```text
   DEEPAGENTS_WORKSPACE_ROOT
   DEEPAGENTS_MEMORY_FILES
   DEEPAGENTS_SKILL_DIRS
   ```

   请求级覆盖：

   ```json
   {
     "agent_code": "lineage-agent",
     "memory_files": ["/AGENTS.md", "/.deepagents/agents/lineage/AGENTS.md"],
     "skill_dirs": ["/.deepagents/skills/lineage"],
     "tool_allowlist": ["metadata.search", "lineage.analyze"]
   }
   ```

3. Router MVP

   支持规则优先、模型兜底：

   ```text
   用户手动选择 Agent -> 直接使用该 Agent
   Agent 关键词/标签命中 -> 使用规则路由
   规则不确定 -> 调用模型分类
   置信度低 -> 回退通用助手，并提示可选择专业 Agent
   ```

4. Run Event 基础表

   建议新增：

   ```text
   ai_agent_run
   ai_agent_run_event
   ai_agent_tool_call
   ```

   事件类型至少包含：

   ```text
   routing_started
   routing_completed
   agent_selected
   model_stream
   tool_call_started
   tool_call_completed
   tool_call_failed
   run_completed
   run_failed
   ```

5. ARK 前端展示

   在现有 ChatGPT 风格消息中展示：

   ```text
   正在识别任务
   已选择 lineage-agent
   正在调用 DeepAgents
   正在生成结果
   ```

6. 权限默认值

   DeepAgents 默认只读：

   ```text
   write_file: deny
   edit_file: deny
   execute: deny 或不暴露
   ```

### 3.3 验收标准

- ARK 中不手动选择 Agent 时，系统可以根据用户输入自动选择一个 Agent。
- 用户手动选择 Agent 时，Router 不覆盖用户选择。
- DeepAgents 可以加载平台级 `/AGENTS.md` 和 Agent 专属 `AGENTS.md`。
- DeepAgents 可以加载 Agent 专属 skills 目录。
- DeepAgents 文件写入权限默认被拒绝。
- 每次对话都生成一条 `ai_agent_run` 记录。
- Router 决策、选中 Agent、模型流式输出至少写入 `ai_agent_run_event`。
- 前端可以展示“任务识别 -> Agent 选择 -> 生成中 -> 完成”的过程。
- 后端编译通过：`cd urgs-api && ./mvnw clean compile -DskipTests`。
- 前端类型检查通过：`cd urgs-web && npx tsc --noEmit`。
- DeepAgents 测试通过：`cd urgs-deepagents && uv run --frozen --extra dev pytest`。

### 3.4 一期不做

- 不做复杂 Planner。
- 不做多 Agent 并行。
- 不做 Agent 之间自动 handoff。
- 不开放写文件和命令执行。
- 不做完整成本分析和质量评测。

## 4. 二期：Planner / Supervisor 与多 Agent 协作

### 4.1 建设目标

在一期稳定分发的基础上，引入 Planner / Supervisor。复杂任务不再只路由到单个 Agent，而是自动拆解为多个子任务，按串行或并行方式调用专家 Agent，并由 Synthesizer 汇总。

### 4.2 主要交付

1. Planner / Supervisor

   输入：

   ```json
   {
     "user_task": "分析某字段下游影响并给出整改建议",
     "context": {},
     "candidate_agents": ["metadata-agent", "lineage-agent", "report-agent"]
   }
   ```

   输出：

   ```json
   {
     "plan": [
       {
         "step": 1,
         "agent": "metadata-agent",
         "task": "获取目标字段元数据",
         "depends_on": []
       },
       {
         "step": 2,
         "agent": "lineage-agent",
         "task": "分析下游影响",
         "depends_on": [1]
       },
       {
         "step": 3,
         "agent": "report-agent",
         "task": "生成影响评估报告",
         "depends_on": [1, 2]
       }
     ]
   }
   ```

2. 多 Agent 执行器

   支持：

   ```text
   串行执行
   并行执行
   依赖等待
   超时控制
   失败重试
   失败降级
   ```

3. Synthesizer 汇总 Agent

   负责把多个专家结果合并为用户可读答案，避免直接拼接多个 Agent 输出。

4. Evaluator / Guardrails

   最低限度校验：

   ```text
   是否回答用户问题
   是否引用了不存在的工具结果
   是否越权请求写文件/执行命令
   是否包含敏感信息
   是否需要人工确认
   ```

5. Handoff 状态

   支持连续多轮专业对话：

   ```text
   当前会话 active_agent = lineage-agent
   后续问题默认进入 lineage-agent
   用户切换 Agent 或 Router 识别强意图后才切换
   ```

6. Tool Gateway

   工具注册从 Agent 内部移到平台：

   ```text
   rag.search
   metadata.get_table
   metadata.search_columns
   lineage.analyze
   sql.validate
   code.search
   code.read_file
   deploy.read_logs
   ```

   每个 Agent 通过 `tool_allowlist` 绑定可用工具。

7. 前端协作过程展示

   展示：

   ```text
   Planner 拆解了 3 个步骤
   metadata-agent 执行完成
   lineage-agent 执行完成
   report-agent 正在汇总
   evaluator-agent 校验通过
   ```

### 4.3 验收标准

- 复杂问题可以自动生成结构化计划。
- 至少支持 3 个专家 Agent 串行协作。
- 至少支持 2 个无依赖子任务并行执行。
- 子任务失败时，Run 状态明确标记失败原因，并返回可读错误。
- Synthesizer 输出的是合并后的单一答案，不是多个 Agent 原文拼接。
- Evaluator 可以拦截至少 3 类风险：越权工具、敏感信息、结果为空。
- 前端能显示完整多 Agent 执行时间线。
- `ai_agent_run_event` 可以回放一次完整多 Agent 执行过程。
- 每个工具调用都记录输入摘要、输出摘要、耗时、状态。
- active agent 支持跨轮保持和手动切换。
- 后端、前端、DeepAgents 三套验证命令全部通过。

### 4.4 二期不做

- 不做跨机器分布式 Agent runtime。
- 不开放自动写生产数据库。
- 不开放无审批文件写入。
- 不做复杂可视化流程编排器。

## 5. 三期：生产化治理、异步任务与平台化运营

### 5.1 建设目标

把多 Agent 协作从“能用”提升到“可运营、可治理、可度量”。重点是异步长任务、成本质量监控、权限审批、Agent 市场化配置、评测体系和运维能力。

### 5.2 主要交付

1. 异步 Agent Job

   支持长任务：

   ```text
   start_job
   get_job_status
   get_job_result
   cancel_job
   ```

   适用场景：

   ```text
   大型血缘分析
   全库元数据巡检
   大批量 SQL 审查
   生产问题诊断
   报告生成
   ```

2. Human-in-the-loop 审批

   需要审批的动作：

   ```text
   文件写入
   命令执行
   数据库变更
   生产环境操作
   外部系统调用
   大额 token 消耗
   ```

3. Agent 配置中心

   前端支持配置：

   ```text
   Agent 基本信息
   适用场景
   AGENTS.md
   skills
   tools 白名单
   模型参数
   权限策略
   评测集
   上线状态
   ```

4. 观测与成本

   指标：

   ```text
   Agent 调用量
   成功率
   平均耗时
   平均 token
   工具失败率
   Router 命中率
   人工介入率
   用户采纳率
   ```

5. 自动评测

   每个 Agent 维护评测集：

   ```text
   输入样例
   期望路由
   期望工具
   期望答案要点
   禁止行为
   ```

   发布前必须跑：

   ```text
   Router 回归测试
   Agent 输出质量测试
   工具权限测试
   敏感信息测试
   ```

6. Agent 版本管理

   支持：

   ```text
   草稿
   灰度
   已发布
   已下线
   回滚
   ```

7. 企业权限与审计

   支持按角色控制：

   ```text
   谁可以使用 Agent
   谁可以编辑 Agent
   谁可以审批高危操作
   谁可以查看 trace
   谁可以导出结果
   ```

### 5.3 验收标准

- 长任务可以后台运行，刷新页面后仍可查看进度和结果。
- 用户可以取消正在执行的 Agent Job。
- 高危工具调用必须进入审批流，未审批不得执行。
- Agent 配置支持版本化发布和回滚。
- 每个 Agent 有独立评测集，并能在发布前一键执行。
- 生产看板能展示调用量、成功率、耗时、token、工具失败率。
- Router 命中率和人工切换率可统计。
- 所有 Agent run 可按用户、会话、Agent、工具、时间范围检索。
- 敏感字段不进入普通日志；trace 展示时做脱敏。
- 支持至少 5 个专业 Agent 稳定运行。
- 关键业务 Agent 有灰度发布能力。
- 后端、前端、DeepAgents、数据库迁移验证全部通过。

## 6. 总体验收标准

三期完成后，系统应满足：

- 用户可以在 ARK 发起自然语言任务，由系统自动分发到合适 Agent。
- 简单任务走单 Agent，复杂任务自动拆解为多 Agent 协作。
- 每个 Agent 有独立 memory、skills、tools、policy。
- 所有执行过程可在前端实时展示。
- 所有 run、step、tool、handoff、evaluation 可落库审计。
- 默认不允许 Agent 写文件、执行命令、操作生产环境。
- 高危动作必须经过审批。
- Agent 能力可以配置、评测、发布、回滚。
- 管理员可以看到调用质量、成本、失败原因和用户采纳情况。

## 7. 推荐优先级

如果资源有限，优先级如下：

```text
P0: Agent Registry、Router MVP、DeepAgents memory/skills、Run Event
P1: Planner / Supervisor、多 Agent 串并行、Synthesizer、Evaluator
P2: 异步 Job、审批、评测、成本和观测
P3: 可视化编排器、Agent 市场、跨机器分布式 Agent runtime
```

## 8. 风险与边界

- 多 Agent 会显著增加 token 成本，必须通过 Router 和 Skills 控制上下文。
- 完全自治 handoff 容易不可控，前两期必须保持中心调度。
- 文件写入和命令执行是高危能力，默认禁用。
- Agent 专属 `AGENTS.md` 和 skills 属于提示词供应链，必须纳入版本管理和审核。
- 工具输出必须摘要化入上下文，避免大结果撑爆模型上下文。
- 评测集必须与 Agent 发布绑定，否则后期无法控制质量回退。

