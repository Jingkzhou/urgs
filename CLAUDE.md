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

**每次代码变更后，必须执行编译验证，确认无语法错误后再 commit。**

- 后端：`cd urgs-api && mvn clean compile -DskipTests`
- 前端：`cd urgs-web && npx tsc --noEmit`（仅检查类型，不打包）
- 若编译失败，必须修复后才能提交，严禁跳过

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
