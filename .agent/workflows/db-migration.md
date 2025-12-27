---
description: 数据库版本变更管理工作流
---

# 数据库变更管理规范

为了确保数据库的版本一致性和自动部署，所有数据库结构的变更（DDL）和必要的基础数据变更（DML）都必须通过迁移脚本进行管理。

## 约束规则

1. **唯一路径**：所有的迁移脚本必须存放在 `/Users/work/Documents/JLbankGit/URGS/urgs-api/src/main/resources/db/migration` 目录下。
2. **命名规范**：使用 Flyway 命名约定：`V<版本号>__<描述>.sql`。
    - 版本号必须在当前最大版本号基础上递增。
    - 描述使用下划线连接单词，简洁明确地描述变更内容。
3. **内容要求**：
    - 脚本应包含详细的注释。
    - DDL 语句必须包含字段注释（COMMENT）。
    - 脚本应考虑幂等性（如使用 `IF NOT EXISTS` 或 `ADD COLUMN IF NOT EXISTS`，尽管标准 SQL 不全支持后者，但在开发环境中需谨慎）。
4. **Agent 执行流程**：
    - 在进行任何代码层面的 Schema 变更前，Agent 必须先在该目录下创建对应的迁移脚本。
    - 在变更完成后，应在 Walkthrough 中明确指出需要在环境中执行该 SQL 脚本（如果尚未自动执行）。

## 示例

```sql
-- V10__Add_SystemId_To_Workflow.sql
ALTER TABLE `sys_workflow` ADD COLUMN `system_id` BIGINT COMMENT '系统ID' AFTER `description`;
```
