DROP PROCEDURE IF EXISTS ExecuteIdempotent_V112;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V112()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    CREATE TABLE IF NOT EXISTS `lineage_review_statement_audit` (
        `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
        `task_id` BIGINT NOT NULL COMMENT '校验任务ID，关联t_lineage_review_task.id',
        `statement_uid` VARCHAR(64) NOT NULL COMMENT 'SQL语句稳定标识',
        `statement_hash` VARCHAR(64) DEFAULT NULL COMMENT '标准化SQL内容哈希',
        `context_group_id` VARCHAR(255) DEFAULT NULL COMMENT '执行上下文分组标识，通常为源码文件或过程范围',
        `source_files_json` JSON DEFAULT NULL COMMENT 'SQL来源文件路径数组',
        `risk_score` INT NOT NULL DEFAULT 0 COMMENT '解析风险评分，分值越高越优先精审',
        `risk_reasons_json` JSON DEFAULT NULL COMMENT '风险原因编码数组',
        `is_high_risk` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否高风险：0否，1是',
        `audit_status` VARCHAR(32) NOT NULL DEFAULT 'PENDING' COMMENT '审核状态：PENDING待处理，SCREENING初筛中，SCREENED_NO_ISSUE初筛无疑点，WAITING_VERIFICATION待精审，VERIFIED_ISSUE精审有疑点，VERIFIED_NO_ISSUE精审无疑点，CACHED使用缓存，FAILED失败，SKIPPED_BUDGET预算跳过',
        `screening_batch_key` VARCHAR(64) DEFAULT NULL COMMENT 'AI初筛微批次标识',
        `is_screening_candidate` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '是否被初筛识别为候选：0否，1是',
        `ai_call_count` INT NOT NULL DEFAULT 0 COMMENT '该语句参与的AI调用次数',
        `issue_count` INT NOT NULL DEFAULT 0 COMMENT '该语句最终保留的疑点数量',
        `skip_reason` VARCHAR(500) DEFAULT NULL COMMENT '失败或跳过原因',
        `evidence_hash` VARCHAR(64) DEFAULT NULL COMMENT '本次证据包哈希，用于结果缓存',
        `result_json` JSON DEFAULT NULL COMMENT '初筛或精审结构化结果',
        `started_time` DATETIME DEFAULT NULL COMMENT '开始审核时间',
        `finished_time` DATETIME DEFAULT NULL COMMENT '完成审核时间',
        `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        CONSTRAINT `pk_lineage_review_statement_audit` PRIMARY KEY (`id`),
        CONSTRAINT `uk_lineage_review_statement_audit_task_statement` UNIQUE (`task_id`, `statement_uid`),
        KEY `idx_lineage_review_statement_audit_task_status` (`task_id`, `audit_status`),
        KEY `idx_lineage_review_statement_audit_task_risk` (`task_id`, `is_high_risk`, `risk_score`),
        KEY `idx_lineage_review_statement_audit_evidence_hash` (`evidence_hash`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='数据血缘 - SQL语句AI事后审核明细';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V112();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V112;
