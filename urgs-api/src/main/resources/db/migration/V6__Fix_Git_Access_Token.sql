DROP PROCEDURE IF EXISTS upgrade_sys_user_v6;

DELIMITER $$
CREATE PROCEDURE upgrade_sys_user_v6()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'sys_user'
        AND COLUMN_NAME = 'git_access_token'
    ) THEN
        ALTER TABLE sys_user ADD COLUMN git_access_token VARCHAR(255) COMMENT 'Git Access Token';
    END IF;
END $$
DELIMITER ;

CALL upgrade_sys_user_v6();
DROP PROCEDURE IF EXISTS upgrade_sys_user_v6;
