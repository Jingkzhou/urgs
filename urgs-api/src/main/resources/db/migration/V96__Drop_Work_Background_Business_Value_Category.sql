DROP PROCEDURE IF EXISTS ExecuteIdempotent_V96;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V96()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_work'
    ) THEN
        IF EXISTS (
            SELECT 1
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'background'
        ) THEN
            ALTER TABLE `sys_work` DROP COLUMN `background`;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'business_value'
        ) THEN
            ALTER TABLE `sys_work` DROP COLUMN `business_value`;
        END IF;

        IF EXISTS (
            SELECT 1
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'sys_work'
              AND COLUMN_NAME = 'category'
        ) THEN
            ALTER TABLE `sys_work` DROP COLUMN `category`;
        END IF;
    END IF;
END$$
DELIMITER ;

CALL ExecuteIdempotent_V96();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V96;
