DROP PROCEDURE IF EXISTS ExecuteIdempotent_V56;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V56()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work' AND COLUMN_NAME = 'background') THEN
        ALTER TABLE `sys_work` ADD COLUMN `background` TEXT COMMENT '需求背景' AFTER `description`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work' AND COLUMN_NAME = 'business_value') THEN
        ALTER TABLE `sys_work` ADD COLUMN `business_value` TEXT COMMENT '业务价值' AFTER `background`;
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'task_type') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `task_type` VARCHAR(64) DEFAULT NULL COMMENT '任务类型' AFTER `description`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'difficulty') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `difficulty` VARCHAR(32) DEFAULT NULL COMMENT '任务难度' AFTER `task_type`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'acceptance_criteria') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `acceptance_criteria` TEXT COMMENT '验收标准' AFTER `required_skills`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'estimated_hours') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `estimated_hours` INT DEFAULT NULL COMMENT '预计工时' AFTER `points`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'completion_description') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `completion_description` TEXT COMMENT '完成说明' AFTER `deadline`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'deliverables') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `deliverables` TEXT COMMENT '交付物链接或附件JSON' AFTER `completion_description`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'actual_hours') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `actual_hours` INT DEFAULT NULL COMMENT '实际投入工时' AFTER `deliverables`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'impact_scope') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `impact_scope` TEXT COMMENT '影响范围' AFTER `actual_hours`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'delay_reported') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `delay_reported` TINYINT(1) DEFAULT 0 COMMENT '是否提前报备延期' AFTER `impact_scope`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'delay_reason') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `delay_reason` TEXT COMMENT '延期原因' AFTER `delay_reported`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'quality_score') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `quality_score` INT DEFAULT NULL COMMENT '质量评分1-5' AFTER `delay_reason`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'review_comment') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `review_comment` TEXT COMMENT '验收意见' AFTER `quality_score`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'reviewer_id') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `reviewer_id` VARCHAR(64) DEFAULT NULL COMMENT '验收人ID' AFTER `review_comment`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'submitted_at') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `submitted_at` DATETIME DEFAULT NULL COMMENT '提交验收时间' AFTER `reviewer_id`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'reviewed_at') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `reviewed_at` DATETIME DEFAULT NULL COMMENT '验收时间' AFTER `submitted_at`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'rework_count') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `rework_count` INT DEFAULT 0 COMMENT '返工次数' AFTER `reviewed_at`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'bonus_points') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `bonus_points` INT DEFAULT 0 COMMENT '奖励积分' AFTER `rework_count`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'penalty_points') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `penalty_points` INT DEFAULT 0 COMMENT '惩罚积分' AFTER `bonus_points`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'final_points') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `final_points` INT DEFAULT 0 COMMENT '最终KPI积分' AFTER `penalty_points`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_work_task' AND COLUMN_NAME = 'kpi_period') THEN
        ALTER TABLE `sys_work_task` ADD COLUMN `kpi_period` VARCHAR(16) DEFAULT NULL COMMENT 'KPI归属周期YYYY-MM' AFTER `final_points`;
    END IF;

    CREATE TABLE IF NOT EXISTS `sys_task_appeal` (
        `id` VARCHAR(64) NOT NULL COMMENT '主键ID',
        `task_id` VARCHAR(64) NOT NULL COMMENT '任务ID',
        `applicant_id` VARCHAR(64) NOT NULL COMMENT '申诉人ID',
        `reason` TEXT COMMENT '申诉原因',
        `expected_result` TEXT COMMENT '期望结果',
        `status` VARCHAR(32) DEFAULT 'PENDING' COMMENT '状态',
        `resolver_id` VARCHAR(64) DEFAULT NULL COMMENT '处理人ID',
        `resolution` TEXT COMMENT '处理结论',
        `resolved_at` DATETIME DEFAULT NULL COMMENT '处理时间',
        `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
        `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
        PRIMARY KEY (`id`),
        KEY `idx_task_appeal_task` (`task_id`),
        KEY `idx_task_appeal_applicant` (`applicant_id`),
        KEY `idx_task_appeal_status` (`status`, `create_time`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='工作市场任务KPI申诉表';

    UPDATE `sys_work_task`
    SET `rework_count` = IFNULL(`rework_count`, 0),
        `bonus_points` = IFNULL(`bonus_points`, 0),
        `penalty_points` = IFNULL(`penalty_points`, 0),
        `final_points` = IFNULL(`final_points`, 0);
END$$
DELIMITER ;
CALL ExecuteIdempotent_V56();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V56;
