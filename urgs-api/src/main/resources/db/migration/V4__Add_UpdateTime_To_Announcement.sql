DROP PROCEDURE IF EXISTS upgrade_v4_add_update_time;

DELIMITER $$
CREATE PROCEDURE upgrade_v4_add_update_time()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sys_announcement'
        AND COLUMN_NAME = 'update_time'
    ) THEN
        ALTER TABLE sys_announcement ADD COLUMN update_time DATETIME DEFAULT NULL COMMENT '更新时间';
    END IF;
END $$
DELIMITER ;

CALL upgrade_v4_add_update_time();
DROP PROCEDURE IF EXISTS upgrade_v4_add_update_time;
