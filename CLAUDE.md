# CLAUDE.md - Claude Code 项目约束

> 本文件是 Claude Code 的顶级约束，所有 Agent 行为必须遵循。

## 核心强制规则

### 1. 数据库变更必须同步 Flyway 迁移脚本

**任何对 JPA Entity (`@Entity`) 的字段新增、修改、删除，都必须在同一次 commit 中创建对应的 Flyway 迁移脚本。**

- 迁移脚本路径：`urgs-api/src/main/resources/db/migration/V<N>__<描述>.sql`
- 创建前先查看当前最大版本号：`ls urgs-api/src/main/resources/db/migration/ | sort -V | tail -1`
- 使用幂等存储过程模式（`IF NOT EXISTS` 检查 + `DECLARE CONTINUE HANDLER`）
- 详细规范见 `.agent/workflows/db-migration.md`

### 2. 编码规范

- 详细规范见 `.agent/coding_standards.md`
- 后端遵循 Controller → Service → Repository 分层
- 前端使用 React 函数式组件 + Hooks + Ant Design + TailwindCSS
- 所有计划和文档使用中文

### 3. 大文件拆分询问机制

**开发过程中如果需要修改的源代码文件已经明显过大，Agent 必须先询问用户是否要顺手拆分，再继续编码。**

- 适用范围：`.java` / `.ts` / `.tsx` / `.js` / `.jsx` / `.py` 等人工维护的源代码文件
- 建议触发线：单文件超过 800 行，或虽然未超过 800 行但已经出现多职责混杂、状态/方法过多、组件过深等明显可维护性问题
- 强提醒触发线：单文件超过 1200 行时，必须优先询问是否拆分
- 询问方式：先简要说明“为什么这个文件建议拆分、拟按什么职责边界拆、预计拆出哪些文件”，等待用户确认后再实施
- 如果用户不同意拆分：只做本次需求所需的局部修改，不借机做大范围重构
- 不适用范围：数据库迁移 SQL、测试 golden 数据、自动生成文件、第三方产物、图片/PDF/Office 等资产文件

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

如果 gstack 技能无法使用，请运行：`cd .claude/skills/gstack && ./setup`（需要先安装 bun）

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
