-- V42__Add_Priority_To_Task_And_Instance.sql
DROP PROCEDURE IF EXISTS upgrade_v42_add_priority;

DELIMITER $$
CREATE PROCEDURE upgrade_v42_add_priority()
BEGIN
    -- Check sys_task
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task' AND COLUMN_NAME = 'priority'
    ) THEN
        ALTER TABLE sys_task ADD COLUMN priority INT DEFAULT 0 COMMENT 'Priority';
    END IF;

    -- Check sys_task_instance
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_instance' AND COLUMN_NAME = 'priority'
    ) THEN
        ALTER TABLE sys_task_instance ADD COLUMN priority INT DEFAULT 0 COMMENT 'Priority' AFTER log_content;
    END IF;
END $$
DELIMITER ;

CALL upgrade_v42_add_priority();
DROP PROCEDURE IF EXISTS upgrade_v42_add_priority;
