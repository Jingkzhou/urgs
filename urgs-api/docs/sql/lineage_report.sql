-- 血缘分析报告表
CREATE TABLE IF NOT EXISTS `lineage_report` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `table_name` VARCHAR(200) NOT NULL COMMENT '表名',
    `column_name` VARCHAR(200) NOT NULL COMMENT '字段名',
    `report_content` LONGTEXT NOT NULL COMMENT '报告内容 (Markdown)',
    `upstream_count` INT DEFAULT 0 COMMENT '上游节点数',
    `downstream_count` INT DEFAULT 0 COMMENT '下游节点数',
    `ai_model` VARCHAR(100) COMMENT '使用的 AI 模型',
    `status` VARCHAR(20) DEFAULT 'completed' COMMENT '状态: generating/completed/failed',
    `create_by` VARCHAR(100) COMMENT '创建人',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_table_column` (`table_name`, `column_name`),
    INDEX `idx_create_time` (`create_time`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='血缘分析报告';
