-- Add system_id column to sys_workflow table
DROP PROCEDURE IF EXISTS upgrade_v10_workflow_system_id;

DELIMITER $$
CREATE PROCEDURE upgrade_v10_workflow_system_id()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sys_workflow'
        AND COLUMN_NAME = 'system_id'
    ) THEN
        ALTER TABLE `sys_workflow` ADD COLUMN `system_id` BIGINT COMMENT '系统ID' AFTER `description`;
    END IF;
END $$
DELIMITER ;

CALL upgrade_v10_workflow_system_id();
DROP PROCEDURE IF EXISTS upgrade_v10_workflow_system_id;
