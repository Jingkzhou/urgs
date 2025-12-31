// ============================================
// Neo4j 血缘图索引配置
// 用于优化查询性能
// ============================================

// 1. Table 节点索引 - 按名称查询
CREATE INDEX idx_table_name IF NOT EXISTS FOR (t:Table) ON (t.name);

// 2. Column 节点索引 - 按名称和所属表查询（最常用）
CREATE INDEX idx_column_name IF NOT EXISTS FOR (c:Column) ON (c.name);
CREATE INDEX idx_column_table IF NOT EXISTS FOR (c:Column) ON (c.table);

// 3. Column 复合索引 - 用于精确匹配 (name, table) 组合
CREATE INDEX idx_column_name_table IF NOT EXISTS FOR (c:Column) ON (c.name, c.table);

// 4. LineageVersion 节点索引
CREATE INDEX idx_version_id IF NOT EXISTS FOR (v:LineageVersion) ON (v.id);
CREATE INDEX idx_version_created IF NOT EXISTS FOR (v:LineageVersion) ON (v.createdAt);

// ============================================
// 验证索引是否创建成功
// ============================================
// 执行以下命令查看所有索引：
// SHOW INDEXES;
