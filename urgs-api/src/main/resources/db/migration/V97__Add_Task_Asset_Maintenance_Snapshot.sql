DROP PROCEDURE IF EXISTS ExecuteIdempotent_V97;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V97()
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
          AND COLUMN_NAME = 'asset_maintenance_snapshot'
    ) THEN
        ALTER TABLE `sys_work_task`
            ADD COLUMN `asset_maintenance_snapshot` LONGTEXT
                COMMENT '资产同步审核通过时的维护记录JSON快照'
                AFTER `review_comment`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V97();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V97;
