DROP PROCEDURE IF EXISTS ExecuteIdempotent_V103;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V103()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
    ) AND NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_user_git_identity'
          AND COLUMN_NAME = 'access_token'
    ) THEN
        ALTER TABLE `sys_user_git_identity`
            ADD COLUMN `access_token` VARCHAR(500) DEFAULT NULL COMMENT 'Git访问令牌' AFTER `git_user_id`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V103();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V103;
