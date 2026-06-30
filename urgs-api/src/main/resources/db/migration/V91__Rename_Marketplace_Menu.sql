DROP PROCEDURE IF EXISTS ExecuteIdempotent_V91;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V91()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_function'
    ) THEN
        IF EXISTS (
            SELECT 1 FROM `sys_function`
            WHERE `code` = 'marketplace'
              AND `name` <> '任务中心'
        ) THEN
            UPDATE `sys_function`
            SET `name` = '任务中心'
            WHERE `code` = 'marketplace';
        END IF;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V91();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V91;
