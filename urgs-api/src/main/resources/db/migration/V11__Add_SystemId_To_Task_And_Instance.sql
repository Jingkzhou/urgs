DROP PROCEDURE IF EXISTS upgrade_v11_task_system_id;

DELIMITER $$
CREATE PROCEDURE upgrade_v11_task_system_id()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task' AND COLUMN_NAME = 'system_id'
    ) THEN
        ALTER TABLE sys_task ADD COLUMN system_id BIGINT COMMENT '关联系统ID';
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_task_instance' AND COLUMN_NAME = 'system_id'
    ) THEN
        ALTER TABLE sys_task_instance ADD COLUMN system_id BIGINT COMMENT '关联系统ID';
    END IF;
END $$
DELIMITER ;

CALL upgrade_v11_task_system_id();
DROP PROCEDURE IF EXISTS upgrade_v11_task_system_id;
