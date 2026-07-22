# AGENTS.md - Codex 项目约束

> 本文件是 Codex 的顶级约束，所有 Agent 行为必须遵循。

## 核心强制规则

### 1. 数据库变更必须同步 Flyway 迁移脚本

**任何对 JPA Entity (`@Entity`) 的字段新增、修改、删除，都必须在同一次 commit 中创建对应的 Flyway 迁移脚本。**

- 迁移脚本路径：`urgs-api/src/main/resources/db/migration/V<N>__<描述>.sql`
- 创建迁移脚本前，必须同时检查迁移目录和目标数据库中的最大 Flyway 版本号：
  - 目录检查：`ls urgs-api/src/main/resources/db/migration/ | sort -V | tail -1`
  - 数据库检查：`SELECT MAX(CAST(version AS UNSIGNED)) AS max_version FROM flyway_schema_history WHERE success = 1;`
- 新迁移文件的版本号 `N` 必须大于上述两个最大版本号；禁止复用已有版本号或修改已执行的迁移脚本
- 使用幂等存储过程模式（`IF NOT EXISTS` 检查 + `DECLARE CONTINUE HANDLER`）
- 详细规范见 `.agent/workflows/db-migration.md`

### 2. 编码规范

- 详细规范见 `.agent/coding_standards.md`
- 后端遵循 Controller → Service → Repository 分层
- 前端使用 React 函数式组件 + Hooks + Ant Design + TailwindCSS
- 所有计划和文档使用中文

### 3. 合理组件与职责边界开发机制

**不要按代码行数强制拆分；编写时应先按职责边界、组件模式和现有项目结构组织代码。**

- 新增功能时，优先把代码放在最贴近业务语义的位置，避免把状态、展示、数据请求、格式化、校验、工具函数混在同一个模块里。
- 前端遵循“容器负责数据与状态、视图组件负责展示、Hook 封装可复用交互逻辑、类型/API/工具函数独立维护”的组件模式；只有确有复用或职责独立时才抽出新文件。
- 后端遵循 Controller / Service / Repository / Entity / DTO 的职责边界；新增逻辑应落在对应层级，不为单次使用场景提前抽象。
- 修改已有大文件时，如果本次需求只是局部修复或小范围调整，应直接做外科手术式修改，并在回复中说明可选的后续整理点；不要因为文件很大就打断任务或强制拆分。
- 如果本次需求会新增明显独立的职责、复杂状态或可复用能力，应优先创建相邻的小组件、Hook、Service、DTO 或工具模块，让新代码从一开始保持清晰边界。
- 如果完成需求必须进行较大范围拆分或重构，应先说明拟按什么职责边界拆、预计影响哪些文件、验证方式是什么，等待用户确认后再实施。
- 不适用范围：数据库迁移 SQL、测试 golden 数据、自动生成文件、第三方产物、图片/PDF/Office 等资产文件。

### 4. 编译验证（自检门禁）

**代码变更后需要编译验证，但前端不要求每次改动都执行编译。**

- 后端改动：必须执行 `cd urgs-api && mvn clean compile -DskipTests`
- 前端改动：默认不强制每次执行编译/类型检查
- 以下前端场景必须执行一次验证（`npx tsc --noEmit` 或 `npm run build`）：
  - 修改构建配置（如 `vite.config.ts`、`tsconfig*.json`）
  - 修改全局依赖、路由装配、公共类型定义、API 基础封装
  - 用户明确要求“编译通过/构建验证”
- 若执行了编译且失败，必须修复后再提交

### 5. 禁止使用 Unicode 弯引号（全角引号）

**JSX/TSX 代码中的字符串属性值必须使用 ASCII 直引号 `"` `'`，严禁使用 Unicode 弯引号 `"` `"` `'` `'`。**

- 常见场景：从文档/浏览器复制粘贴文本时引入弯引号
- Babel/TSC 遇到弯引号会报 `Unexpected character` 编译错误
- Agent 生成代码时必须自查引号字符

### 6. 前后端参数命名一致性

**前端 API 调用参数名必须与后端 Controller 方法参数名完全一致。**

- 修改后端参数名时，必须同步修改前端 `api/` 目录下的对应接口定义
- 新增后端接口时，前端 TypeScript 接口类型必须同步创建

### 7. Entity 字段变更 Flyway 清单（加强版）

**在 commit 前，Agent 必须执行以下自检：**

1. `git diff --cached` 检查是否有 `@Column` / `@Entity` 变更
2. 如有，确认 `db/migration/` 目录下是否有对应的新 `V<N>__*.sql` 文件
3. 如缺失，立即创建迁移脚本后再 commit
4. 迁移脚本必须包含 `IF NOT EXISTS` 幂等检查

### 8. 项目结构

- 后端：`urgs-api/`（Spring Boot + JPA + Flyway + MySQL）
- 前端：`urgs-web/`（React + TypeScript + Vite + Ant Design）
- 数据库迁移：`urgs-api/src/main/resources/db/migration/`
- 工作流文档：`.agent/workflows/`

### 8.1 Windows 客户端版本与内网自动升级

Windows 客户端基于 Tauri，自动升级以已安装客户端版本与内网 `latest.json` 中的版本进行 SemVer 比较，**不比较代码或安装包文件内容**。

- 每次需要让已安装客户端自动升级时，新安装包版本必须严格大于已安装版本；重新发布相同版本号不会触发升级。
- 版本号必须在以下两个文件中保持完全一致：
  - `urgs-desktop/src-tauri/tauri.conf.json` 的 `version`；该版本用于更新清单和部署包。
  - `urgs-desktop/src-tauri/Cargo.toml` 的 `package.version`；该版本用于 Rust/Tauri 包元数据。
- 版本规则遵循 SemVer：修复和小范围体验调整升补丁版本（如 `0.1.0 → 0.1.1`）；一批可感知的新功能升次版本（如 `0.1.x → 0.2.0`）；存在不兼容升级或重大正式发布时才升主版本。
- 禁止在每次日常代码修改或本地构建时自动升版本。仅在用户明确要求“发 Windows 升级包”“打安装包并部署 SIT/PRO”或等价发布动作，并且待发布代码已确认后，统一修改版本号。
- 发布 Windows 升级包时，Agent 应同步更新上述两个版本号，完成提交和推送后触发 Windows 签名构建；再将签名工件打入部署包，由部署脚本发布内网 `latest.json`。不得将未提交或未推送的工作区代码作为正式升级包发布。

### 9. CodeGraph 使用策略

**当仓库根目录存在 `.codegraph/` 时，分析代码结构、调用链、影响面、符号位置前，必须优先使用 CodeGraph 做第一轮定位，以减少无效文件读取和 token 消耗。**

- 优先使用 MCP 工具：`codegraph_explore`、`codegraph_node`、`codegraph_impact`、`codegraph_callers`、`codegraph_callees`、`codegraph_files`。
- 如果 MCP 工具未在当前会话暴露，使用等价 CLI：`codegraph explore "<问题或符号>"`、`codegraph node "<符号或文件>"`、`codegraph impact "<符号>"`。
- CodeGraph 用于缩小范围；涉及 Spring 拦截器、配置、Flyway、MyBatis XML、前端路由/API 字符串、运行时行为时，仍需用源码读取或 `rg` 补充验证。
- 修改代码前如涉及公共接口、Controller、Service、Mapper、前端 API 封装，应先跑一次 `codegraph impact "<目标符号>"` 或等价查询确认影响面。

### 10. 数据库表与字段命名规范

**表名必须表达“业务域 + 业务对象”，不得再把 `sys_`、`t_` 当作无意义的通用前缀。表名和字段名应让不了解代码的人也能从名称与注释判断其用途。**

#### 10.1 总体规则

- 表名、字段名、索引名统一使用小写 `snake_case`，禁止拼音、大小写混用和无约定缩写。
- 表名使用单数名词，格式为 `<业务域>_<聚合根>[_<明细角色>]`，例如 `sched_task`、`sched_task_instance`、`market_task_application`。
- 新表禁止使用无业务含义的 `t_`、`biz_`、`data_`、`common_` 前缀；`sys_` 也不得表示“系统里的一张表”。
- 名称应优先表达业务语义，禁止单独使用 `info`、`data`、`detail`、`record`、`list`、`temp` 等模糊词；确有临时表时使用明确用途和生命周期，并在迁移脚本中说明清理方式。
- MySQL 标识符上限为 64 个字符，项目表名目标不超过 48 个字符；超长时只允许使用本节登记的业务域前缀和团队已确认的通用缩写。
- 新增业务域前缀前，必须先在本节“业务域前缀表”登记含义、边界和示例，禁止同一业务域出现多个同义前缀。

#### 10.2 业务域前缀表

| 前缀 | 业务边界 | 示例 |
|------|----------|------|
| `sys_` | 平台基础管理、身份、组织、认证、授权和平台级配置 | `sys_user`、`sys_role`、`sys_permission`、`sys_org`、`sys_auth_session` |
| `sched_` | 工作流、任务编排、调度计划、执行实例、依赖和执行日志 | `sched_workflow`、`sched_task_definition`、`sched_task_instance`、`sched_task_dependency` |
| `market_` | 工作发布、任务市场、申领、竞标、评价和积分闭环 | `market_work`、`market_task`、`market_task_application` |
| `meta_` | 技术元数据、数据模型、码表、目录和物理结构 | `meta_model_table`、`meta_model_field`、`meta_code_table` |
| `reg_` | 监管报表、监管元素、监管资产及其业务绑定 | `reg_table`、`reg_element`、`reg_table_model_rel` |
| `lineage_` | 数据血缘分析、审核、问题、缓存和报告 | `lineage_analysis`、`lineage_review_task` |
| `ops_` | 基础设施、运行监控、部署环境和运维台账 | `ops_infrastructure_asset`、`ops_monitor_sample`、`ops_deployment` |
| `ver_` | 代码仓库、版本包、发布策略、流水线和发布记录 | `ver_repository`、`ver_package`、`ver_release_record` |
| `ai_` | AI 配置、Agent、会话、消息和用量 | `ai_agent`、`ai_chat_session`、`ai_usage_log` |
| `kb_` | 知识库、文件、目录和标签 | `kb_document`、`kb_folder`、`kb_tag` |
| `doc_` | 在线文档、文档权限和协作关系 | `doc_document`、`doc_document_permission` |
| `im_` | 即时通信用户、会话、群组、好友和消息 | `im_conversation`、`im_group_member`、`im_message` |

边界判断以数据的业务归属为准，而不是以页面菜单、Java 包名或调用方为准。例如：

- `sys_task` 存储的是工作流节点的任务定义，包含任务类型、执行内容、Cron、数据日期规则、优先级等，语义上属于调度编排域，目标命名应为 `sched_task_definition`，不是系统表。
- `sys_task_instance`、`sys_task_dependency` 应归入 `sched_` 域；工作市场中的任务申请、评论、申诉、日志应归入 `market_` 域，两类“任务”不得继续共享含糊的 `sys_task*` 命名空间。
- `t_quartz_task*` 属于调度执行域；后续治理时应先确认它与 `sys_task*` 的模型边界，再统一到 `sched_`，不得继续新增 `t_quartz_*` 表。

#### 10.3 聚合与表角色命名

- 聚合主表使用 `<域>_<对象>`，子表必须保留聚合根名称，例如 `market_task_application`，不得简写成无法定位归属的 `task_application`。
- 纯多对多关系表统一使用 `<左对象>_<右对象>_rel`；有独立业务属性或生命周期的关系不得伪装成 `_rel`，应按业务对象命名。
- 层级成员使用 `_member`，执行实例使用 `_instance`，配置使用 `_config`，规则使用 `_rule`，快照使用 `_snapshot`，操作流水使用 `_log`，状态变更历史使用 `_history`。
- 同库存在多个同名概念时，外键和子表名必须带聚合或业务域限定。例如同时存在调度任务和市场任务时，跨域引用应使用 `sched_task_id` 或 `market_task_id`，不得只写无法判断目标的 `task_id`。

#### 10.4 字段命名

- 主键默认命名为 `id`；外键命名为 `<被引用对象>_id`，字段类型、长度和有无符号属性必须与目标主键完全一致。
- 业务编码使用 `<对象>_code`，显示名称使用 `<对象>_name`；只有表内语义唯一且不会产生歧义时才可简化为 `code`、`name`。
- 布尔字段使用 `is_`、`has_`、`can_` 前缀，数据库类型使用 `TINYINT(1)`，并在字段注释中明确 `0/1` 含义。
- 只有一个生命周期状态时可使用 `status`；存在多个状态维度时必须写成 `run_status`、`review_status`、`sync_status` 等，不得使用 `status1`、`type2`。
- 类型、状态、来源、模式等枚举字段必须在字段注释中列出全部合法值及含义；禁止只有“状态”“类型”这类无信息注释，也禁止无注释的魔法数字。
- 时间字段统一使用 `create_time`、`update_time`、`delete_time` 和 `<业务动作>_time`；同一聚合内禁止混用 `create_time` 与 `created_at`。扩展存量聚合时遵循该聚合现有风格，新建聚合默认使用 `*_time`。
- 审计操作人统一使用 `created_by`、`updated_by`；软删除统一使用 `is_deleted`、`delete_time`、`deleted_by`，不得混用 `del_flag`、`deleted`、`is_delete`。
- 数量、金额、时长、容量字段必须体现单位或含义，例如 `retry_count`、`amount_cent`、`timeout_seconds`、`size_bytes`，不得仅命名为 `num`、`value`、`time`。
- JSON 字段使用 `<业务含义>_json`，例如 `execution_config_json`；字段注释必须说明核心结构或指向对应 DTO，禁止使用 `content`、`ext` 保存未说明结构的 JSON。
- 大文本字段仍需表达内容，例如 `error_message`、`execution_log`、`review_comment`，不得使用 `text1`、`remark2`。

#### 10.5 注释、索引与约束

- 每张新表必须有中文表注释，格式建议为 `<业务域> - <数据对象及用途>`，例如 `任务调度 - 工作流节点任务定义`；不得只写“任务表”“数据表”。
- 每个业务字段必须有中文字段注释。外键注释需写明目标表，枚举需写明值域，JSON 需写明结构，时间需写明业务动作。
- 主键、唯一索引、普通索引、外键约束分别使用 `pk_<表名>`、`uk_<表名>_<字段>`、`idx_<表名>_<字段>`、`fk_<表名>_<目标表>`；联合索引字段按索引顺序排列。
- 具有业务唯一性的编码、关系或幂等键必须创建唯一约束，不能只依赖 Service 层查询防重。
- 禁止为了“以后可能会查”而建立冗余索引；新增索引时应能对应到实际查询条件、关联条件或排序路径。

#### 10.6 存量表治理与变更门禁

- 本规范对新表立即生效；存量表不做无需求驱动的批量重命名，避免一次性影响 Entity、Mapper XML、原生 SQL、脚本和外部接口。
- 修改存量歧义表时，应在本次影响范围内补齐或修正表注释、字段注释；需要重命名时，先给出“旧名 → 新名”映射和 CodeGraph 影响分析，经用户确认后再实施。
- 表重命名必须通过 Flyway 完成，并同步修改 Entity 注解、Mapper XML、Repository 原生 SQL、前端接口约定、调度脚本和部署脚本；不得只改 Java 映射。
- 新建表或字段前必须依次回答：属于哪个业务域、核心对象是什么、是主表还是哪种子表、是否与现有概念重名、名称能否在不读代码时判断用途。
- 创建 Flyway 脚本前使用 `rg` 检查同名表和字段，涉及公共 Entity、Mapper、Service 或跨模块 SQL 时先执行 `codegraph impact`；提交前同时执行本文件第 1、7 节的 Flyway 自检。

## 通用行为准则

以下准则用于减少常见的 LLM 编码失误。与项目强制规则冲突时，以本文件中的项目强制规则为准；简单任务可按实际情况简化执行，但不得跳过必要的验证和自检。

### 1. 编码前先想清楚

- 不要默认假设需求含义；如果存在不确定性，必须显式说明假设。
- 如果需求存在多种理解，先列出可能解释，不要静默选择其中一种。
- 如果有更简单的方案，必须说明；当需求可能引入不必要复杂度时，应主动提醒。
- 如果关键信息不清楚，先停下并指出困惑点，向用户提问后再继续。

### 2. 简单优先

- 只写满足当前需求的最小代码，不添加未被要求的功能。
- 不为单次使用场景提前抽象。
- 不添加未被要求的“灵活性”“可配置性”。
- 不为实际上不可能发生的场景增加复杂错误处理。
- 如果实现明显可以用更少代码完成，应先简化再提交。

### 3. 外科手术式修改

- 只修改完成当前需求所必需的文件和代码。
- 不借机“顺手优化”相邻代码、注释或格式。
- 不重构没有坏掉、也不属于本次需求范围的代码。
- 匹配现有代码风格，即使个人偏好不同。
- 如果发现无关的死代码或可维护性问题，只在回复中说明，不擅自删除。
- 本次修改造成的无用 import、变量、函数必须清理；但不要删除修改前已存在的无关死代码。
- 每一行变更都应该能追溯到用户请求。

### 4. 目标驱动执行

- 将任务转化为可验证目标，再开始实现。
- 修 bug 时优先明确复现方式；适合写测试的场景，先写能复现问题的测试，再修复。
- 添加校验、规则或行为时，应补充能证明目标达成的测试或验证步骤。
- 多步骤任务应给出简短计划，包含每一步的验证方式。
- 完成后必须按本文件“编译验证（自检门禁）”执行必要验证；如执行验证失败，必须修复后再交付。

## gstack — 虚拟工程团队技能集

本项目已集成 [gstack](https://github.com/garrytan/gstack)，提供一套完整的开发流程斜杠命令。

**所有网页浏览操作必须使用 `/browse` 技能，严禁使用 `mcp__claude-in-chrome__*` 工具。**

如果 gstack 技能无法使用，请运行：`cd .Codex/skills/gstack && ./setup`（需要先安装 bun）

### 可用技能

| 技能命令 | 说明 |
|---------|------|
| `/office-hours` | 产品思维 — 在写代码前重构问题框架 |
| `/plan-ceo-review` | CEO 视角 — 产品战略评审 |
| `/plan-eng-review` | 架构评审 — 数据流、边界情况、测试计划 |
| `/plan-design-review` | 设计评审 — 审查计划中的设计维度 |
| `/design-consultation` | 设计咨询 — 从零构建设计系统 |
| `/review` | 代码审查 — 发现生产级 bug |
| `/investigate` | 调试 — 系统性定位根本原因 |
| `/design-review` | 视觉审查 — 审查并修复 UI 设计问题 |
| `/qa` | QA 测试 — 真实浏览器测试并修复 bug |
| `/qa-only` | QA 报告 — 只报告不修改 |
| `/ship` | 发布 — 同步主干、运行测试、创建 PR |
| `/document-release` | 文档更新 — 发布后同步所有文档 |
| `/retro` | 回顾 — 周度开发指标统计 |
| `/browse` | 浏览器 — 真实 Chromium 网页操作 |
| `/codex` | 第二意见 — OpenAI 独立代码审查 |
| `/careful` | 安全防护 — 危险命令二次确认 |
| `/freeze` | 编辑锁定 — 限制编辑范围到指定目录 |
| `/guard` | 最高安全 — careful + freeze 组合 |
| `/unfreeze` | 解锁 — 移除 freeze 限制 |
| `/gstack-upgrade` | 升级 — 更新 gstack 至最新版本 |

详细使用说明见 `.agent/workflows/gstack-guide.md`
