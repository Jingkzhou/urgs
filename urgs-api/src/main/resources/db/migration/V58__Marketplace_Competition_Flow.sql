DROP PROCEDURE IF EXISTS ExecuteIdempotent_V58;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V58()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND COLUMN_NAME = 'solution') THEN
        ALTER TABLE `sys_task_application` ADD COLUMN `solution` TEXT COMMENT '竞标实施方案' AFTER `message`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND COLUMN_NAME = 'expected_completion_time') THEN
        ALTER TABLE `sys_task_application` ADD COLUMN `expected_completion_time` DATETIME DEFAULT NULL COMMENT '预计完成时间' AFTER `solution`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND COLUMN_NAME = 'review_comment') THEN
        ALTER TABLE `sys_task_application` ADD COLUMN `review_comment` TEXT COMMENT '审批意见' AFTER `status`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND COLUMN_NAME = 'reviewed_by') THEN
        ALTER TABLE `sys_task_application` ADD COLUMN `reviewed_by` VARCHAR(64) DEFAULT NULL COMMENT '审批人ID' AFTER `review_comment`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND COLUMN_NAME = 'reviewed_at') THEN
        ALTER TABLE `sys_task_application` ADD COLUMN `reviewed_at` DATETIME DEFAULT NULL COMMENT '审批时间' AFTER `reviewed_by`;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.STATISTICS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_application' AND INDEX_NAME = 'idx_task_application_applicant_status') THEN
        ALTER TABLE `sys_task_application` ADD KEY `idx_task_application_applicant_status` (`applicant_id`, `status`, `create_time`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V58();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V58;
