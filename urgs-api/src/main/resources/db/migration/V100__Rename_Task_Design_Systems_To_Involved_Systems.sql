DROP PROCEDURE IF EXISTS ExecuteIdempotent_V100;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V100()
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
          AND COLUMN_NAME = 'involved_system_ids'
    ) THEN
        ALTER TABLE `sys_work_task`
            ADD COLUMN `involved_system_ids` LONGTEXT
                COMMENT '涉及系统ID列表JSON'
                AFTER `difficulty`;
    END IF;

    IF EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
          AND COLUMN_NAME = 'design_system_ids'
    ) AND EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work_task'
          AND COLUMN_NAME = 'involved_system_ids'
    ) THEN
        UPDATE `sys_work_task`
        SET `involved_system_ids` = `design_system_ids`
        WHERE `design_system_ids` IS NOT NULL
          AND (`involved_system_ids` IS NULL OR `involved_system_ids` = '');

        ALTER TABLE `sys_work_task`
            DROP COLUMN `design_system_ids`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V100();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V100;
