---
description: 数据库版本变更管理工作流
---

# 数据库变更管理规范

为了确保数据库的版本一致性和自动部署，所有数据库结构的变更（DDL）和必要的基础数据变更（DML）都必须通过迁移脚本进行管理。

## 约束规则

> **⚠️ 强制规则：任何对 JPA Entity 的字段新增/修改/删除，都必须同步创建 Flyway 迁移脚本。没有迁移脚本的 Entity 变更视为未完成。**

1. **唯一路径**：所有的迁移脚本必须存放在 `urgs-api/src/main/resources/db/migration` 目录下。
2. **命名规范**：使用 Flyway 命名约定：`V<版本号>__<描述>.sql`。
    - 版本号必须在当前最大版本号基础上递增（先查看目录中最大版本号）。
    - 描述使用下划线连接单词，简洁明确地描述变更内容。
3. **内容要求**：
    - 脚本应包含详细的注释。
    - DDL 语句必须包含字段注释（COMMENT）。
    - 脚本必须使用幂等存储过程模式，确保重复执行不报错：
      ```sql
      DROP PROCEDURE IF EXISTS ExecuteIdempotent_V<N>;
      DELIMITER $$
      CREATE PROCEDURE ExecuteIdempotent_V<N>()
      BEGIN
          DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;
          -- 使用 IF NOT EXISTS 检查后再执行 ALTER TABLE
      END$$
      DELIMITER ;
      CALL ExecuteIdempotent_V<N>();
      DROP PROCEDURE ExecuteIdempotent_V<N>;
      ```
4. **Agent 执行流程（强制）**：
    - **修改 Entity 字段时，必须在同一次提交中创建对应的 Flyway 迁移脚本。**
    - 迁移脚本的创建不能延后到后续提交，必须与 Entity 变更在同一个 commit 内。
    - 创建迁移脚本前，先执行 `ls db/migration/ | sort -V | tail -1` 确认当前最大版本号。
    - 在变更完成后，应在 Walkthrough 中明确指出需要在环境中执行该 SQL 脚本。
5. **触发条件检查清单**：
    - ✅ 新增 `@Column` 字段 → 需要 `ALTER TABLE ADD COLUMN`
    - ✅ 修改字段类型/长度 → 需要 `ALTER TABLE MODIFY COLUMN`
    - ✅ 删除字段 → 需要 `ALTER TABLE DROP COLUMN`
    - ✅ 新增 `@Entity` 类 → 需要 `CREATE TABLE`
    - ✅ 新增索引/约束 → 需要对应 DDL
    - ❌ 仅修改 Java 逻辑（不涉及数据库结构）→ 无需迁移脚本

## 示例

```sql
-- V10__Add_SystemId_To_Workflow.sql
ALTER TABLE `sys_workflow` ADD COLUMN `system_id` BIGINT COMMENT '系统ID' AFTER `description`;
```
