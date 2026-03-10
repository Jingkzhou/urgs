# SQL 预处理逻辑参考

本文档描述血缘解析引擎在解析前对 SQL 执行的预处理工作。

## 目录
- [处理流程](#处理流程)
- [基础分句](#基础分句)
- [存储过程展开](#存储过程展开)
- [智能切片策略](#智能切片策略)
- [注释降噪](#注释降噪)
- [表名规范化](#表名规范化)

---

## 处理流程

```
原始 SQL
  │
  ├─ 1. SqlSplitter.split()        → 基础分号分句
  │
  ├─ 2. extract_procedure_body()   → 存储过程 BEGIN..END 提取
  │
  ├─ 3. smart_split()              → 超长语句三策略切片
  │     ├─ Strategy 1: VALUES 多行拆分
  │     ├─ Strategy 2: UNION ALL 拆分
  │     └─ Strategy 3: 列宽级拆分
  │
  ├─ 4. remove_comments()          → 注释移除降噪
  │
  └─ 5. GSP preprocess_sql()       → 全角转半角、NOLOGGING 清除
```

## 基础分句

`SqlSplitter.split(sql)` 按分号分割 SQL 脚本：
- 跳过引号内分号（单引号、双引号、反引号）
- 跳过注释内分号（`--`、`#`、`/* */`）
- 支持 `DELIMITER` 指令动态切换分隔符

## 存储过程展开

`SqlSplitter.extract_procedure_body(sql)` 对 `CREATE PROCEDURE/FUNCTION` 语句提取 `BEGIN...END` 内部逻辑体，然后递归调用 `split()` 拆分为独立语句。

## 智能切片策略

当语句超过阈值（默认 10000 字符，通过 `SQLFLOW_CHAR_LIMIT` 环境变量配置）时触发 `smart_split()`：

| 优先级 | 策略                                | 适用场景                             |
| ------ | ----------------------------------- | ------------------------------------ |
| 1      | `split_values_rows`                 | INSERT INTO t VALUES (...), (...)    |
| 2      | `split_union_all`                   | INSERT ... SELECT ... UNION ALL ...  |
| 3      | `split_large_insert_select`         | INSERT INTO t (cols) SELECT ... FROM |
| 4      | `split_large_insert_values_columns` | INSERT INTO t (cols) VALUES (wide)   |

每个策略都具备引号保护和括号深度感知能力。

## 注释降噪

`SqlSplitter.remove_comments(sql)` 移除所有注释：
- 单行注释 `--` 和 `#`
- 块注释 `/* ... */`
- 保留引号内的注释标识符
- 保留换行符以维持格式

## 表名规范化

`normalize_table_name(name)` 统一 GSP 和 sqlglot 输出的表名格式：
- 移除反引号包裹
- 修复 GSP 拆分错误（如 `` `schema`.``.`table` `` → `schema..table`）
- 保持已规范化的名称不变
