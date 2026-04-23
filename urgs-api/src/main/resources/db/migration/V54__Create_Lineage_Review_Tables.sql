DROP PROCEDURE IF EXISTS ExecuteIdempotent_V54;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V54()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `t_lineage_review_task` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `analysis_record_id` VARCHAR(64) NOT NULL COMMENT '关联血缘分析记录ID',
        `repo_id` BIGINT DEFAULT NULL COMMENT '仓库ID',
        `version_id` VARCHAR(64) DEFAULT NULL COMMENT '血缘版本ID',
        `ref` VARCHAR(255) DEFAULT NULL COMMENT 'Git引用',
        `system_key` VARCHAR(255) DEFAULT NULL COMMENT '系统分片标识',
        `path_prefix` VARCHAR(500) DEFAULT NULL COMMENT '目录分片前缀',
        `task_name` VARCHAR(255) DEFAULT NULL COMMENT '任务名称',
        `status` VARCHAR(32) DEFAULT 'PENDING' COMMENT '任务状态',
        `object_count` INT DEFAULT 0 COMMENT '对象总数',
        `processed_count` INT DEFAULT 0 COMMENT '已处理对象数',
        `issue_count` INT DEFAULT 0 COMMENT '疑点数',
        `failed_count` INT DEFAULT 0 COMMENT '失败对象数',
        `ai_call_count` INT DEFAULT 0 COMMENT 'AI调用次数',
        `cache_hit_count` INT DEFAULT 0 COMMENT '缓存命中次数',
        `batch_count` INT DEFAULT 0 COMMENT '处理批次数',
        `token_budget` INT DEFAULT 0 COMMENT '任务token预算',
        `consumed_tokens` INT DEFAULT 0 COMMENT '任务已消耗token',
        `last_error` TEXT COMMENT '最后错误信息',
        `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
        `finished_at` DATETIME DEFAULT NULL COMMENT '结束时间',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_lineage_review_task_scope` (`analysis_record_id`, `path_prefix`(255)),
        KEY `idx_lineage_review_task_record` (`analysis_record_id`),
        KEY `idx_lineage_review_task_status` (`status`, `create_time`),
        KEY `idx_lineage_review_task_repo` (`repo_id`, `version_id`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SQL血缘事后校验任务表';

    CREATE TABLE IF NOT EXISTS `t_lineage_review_issue` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `task_id` BIGINT NOT NULL COMMENT '关联校验任务ID',
        `analysis_record_id` VARCHAR(64) NOT NULL COMMENT '关联血缘分析记录ID',
        `repo_id` BIGINT DEFAULT NULL COMMENT '仓库ID',
        `version_id` VARCHAR(64) DEFAULT NULL COMMENT '血缘版本ID',
        `system_key` VARCHAR(255) DEFAULT NULL COMMENT '系统分片标识',
        `path_prefix` VARCHAR(500) DEFAULT NULL COMMENT '目录分片前缀',
        `table_name` VARCHAR(255) DEFAULT NULL COMMENT '目标表名',
        `column_name` VARCHAR(255) DEFAULT NULL COMMENT '目标字段名',
        `object_type` VARCHAR(32) DEFAULT 'COLUMN' COMMENT '对象类型',
        `issue_type` VARCHAR(64) NOT NULL COMMENT '疑点类型',
        `severity` VARCHAR(16) DEFAULT 'MEDIUM' COMMENT '严重级别',
        `confidence` DECIMAL(5,4) DEFAULT 0 COMMENT '置信度',
        `verdict` VARCHAR(32) DEFAULT 'PENDING' COMMENT 'AI判定',
        `reason` TEXT COMMENT '原因说明',
        `rule_hits` JSON DEFAULT NULL COMMENT '命中规则',
        `suggested_sources` JSON DEFAULT NULL COMMENT '建议来源',
        `evidence_refs` JSON DEFAULT NULL COMMENT '证据引用',
        `graph_snapshot` JSON DEFAULT NULL COMMENT '局部图快照',
        `fingerprint` VARCHAR(64) DEFAULT NULL COMMENT '证据指纹',
        `cache_key` VARCHAR(64) DEFAULT NULL COMMENT '缓存键',
        `review_status` VARCHAR(32) DEFAULT 'PENDING' COMMENT '人工复核状态',
        `reviewer_id` BIGINT DEFAULT NULL COMMENT '复核人ID',
        `reviewer_note` TEXT COMMENT '复核备注',
        `review_time` DATETIME DEFAULT NULL COMMENT '复核时间',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_lineage_review_issue_fp` (`task_id`, `fingerprint`),
        KEY `idx_lineage_review_issue_task` (`task_id`, `severity`, `review_status`),
        KEY `idx_lineage_review_issue_record` (`analysis_record_id`, `system_key`),
        KEY `idx_lineage_review_issue_object` (`table_name`, `column_name`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SQL血缘事后校验疑点表';

    CREATE TABLE IF NOT EXISTS `t_lineage_review_cache` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `cache_key` VARCHAR(64) NOT NULL COMMENT '缓存键',
        `fingerprint` VARCHAR(64) NOT NULL COMMENT '证据指纹',
        `ai_model` VARCHAR(128) DEFAULT NULL COMMENT 'AI模型',
        `confidence` DECIMAL(5,4) DEFAULT 0 COMMENT '缓存置信度',
        `verdict` VARCHAR(32) DEFAULT 'PENDING' COMMENT '缓存判定',
        `result_json` JSON DEFAULT NULL COMMENT '缓存结果',
        `hit_count` INT DEFAULT 0 COMMENT '命中次数',
        `last_hit_at` DATETIME DEFAULT NULL COMMENT '最后命中时间',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_lineage_review_cache_key` (`cache_key`),
        KEY `idx_lineage_review_cache_fp` (`fingerprint`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SQL血缘事后校验缓存表';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V54();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V54;
