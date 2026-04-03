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

### 3. 编译验证（自检门禁）

**代码变更后需要编译验证，但前端不要求每次改动都执行编译。**

- 后端改动：必须执行 `cd urgs-api && mvn clean compile -DskipTests`
- 前端改动：默认不强制每次执行编译/类型检查
- 以下前端场景必须执行一次验证（`npx tsc --noEmit` 或 `npm run build`）：
  - 修改构建配置（如 `vite.config.ts`、`tsconfig*.json`）
  - 修改全局依赖、路由装配、公共类型定义、API 基础封装
  - 用户明确要求“编译通过/构建验证”
- 若执行了编译且失败，必须修复后再提交

### 4. 禁止使用 Unicode 弯引号（全角引号）

**JSX/TSX 代码中的字符串属性值必须使用 ASCII 直引号 `"` `'`，严禁使用 Unicode 弯引号 `"` `"` `'` `'`。**

- 常见场景：从文档/浏览器复制粘贴文本时引入弯引号
- Babel/TSC 遇到弯引号会报 `Unexpected character` 编译错误
- Agent 生成代码时必须自查引号字符

### 5. 前后端参数命名一致性

**前端 API 调用参数名必须与后端 Controller 方法参数名完全一致。**

- 修改后端参数名时，必须同步修改前端 `api/` 目录下的对应接口定义
- 新增后端接口时，前端 TypeScript 接口类型必须同步创建

### 6. Entity 字段变更 Flyway 清单（加强版）

**在 commit 前，Agent 必须执行以下自检：**

1. `git diff --cached` 检查是否有 `@Column` / `@Entity` 变更
2. 如有，确认 `db/migration/` 目录下是否有对应的新 `V<N>__*.sql` 文件
3. 如缺失，立即创建迁移脚本后再 commit
4. 迁移脚本必须包含 `IF NOT EXISTS` 幂等检查

### 7. 项目结构

- 后端：`urgs-api/`（Spring Boot + JPA + Flyway + MySQL）
- 前端：`urgs-web/`（React + TypeScript + Vite + Ant Design）
- 数据库迁移：`urgs-api/src/main/resources/db/migration/`
- 工作流文档：`.agent/workflows/`

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
