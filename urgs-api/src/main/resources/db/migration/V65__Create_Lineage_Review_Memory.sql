DROP PROCEDURE IF EXISTS ExecuteIdempotent_V65;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V65()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `t_lineage_review_memory` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `title` VARCHAR(255) NOT NULL COMMENT '记忆标题',
        `status` VARCHAR(32) NOT NULL DEFAULT 'ACTIVE' COMMENT '状态：ACTIVE 生效，ARCHIVED 归档',
        `content` MEDIUMTEXT NOT NULL COMMENT '走查记忆内容',
        `target_pattern` VARCHAR(512) DEFAULT NULL COMMENT '适用目标对象模式',
        `issue_type` VARCHAR(64) DEFAULT NULL COMMENT '来源疑点类型',
        `rule_hits` JSON DEFAULT NULL COMMENT '来源规则命中',
        `source_issue_id` BIGINT DEFAULT NULL COMMENT '来源疑点ID',
        `source_task_id` BIGINT DEFAULT NULL COMMENT '来源走查任务ID',
        `analysis_record_id` VARCHAR(64) DEFAULT NULL COMMENT '来源分析记录ID',
        `repo_id` BIGINT DEFAULT NULL COMMENT '仓库ID',
        `version_id` VARCHAR(64) DEFAULT NULL COMMENT '血缘版本ID',
        `system_key` VARCHAR(255) DEFAULT NULL COMMENT '系统分片标识',
        `path_prefix` VARCHAR(500) DEFAULT NULL COMMENT '目录分片前缀',
        `created_by` BIGINT DEFAULT NULL COMMENT '创建人ID',
        `updated_by` BIGINT DEFAULT NULL COMMENT '更新人ID',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        UNIQUE KEY `uk_lineage_review_memory_issue` (`source_issue_id`),
        KEY `idx_lineage_review_memory_status` (`status`, `update_time`),
        KEY `idx_lineage_review_memory_issue_type` (`issue_type`),
        KEY `idx_lineage_review_memory_target` (`target_pattern`(255))
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='SQL血缘走查记忆表';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V65();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V65;
