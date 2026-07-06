DROP PROCEDURE IF EXISTS ExecuteIdempotent_V99;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V99()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
          AND COLUMN_NAME = 'design_system_ids'
    ) THEN
        ALTER TABLE `sys_work_task`
            ADD COLUMN `design_system_ids` LONGTEXT
                COMMENT '关联设计系统ID列表JSON'
                AFTER `difficulty`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V99();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V99;
