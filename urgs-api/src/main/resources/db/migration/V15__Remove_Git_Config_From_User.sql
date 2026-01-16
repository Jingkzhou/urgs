-- V15__Remove_Git_Config_From_User.sql
-- Remove git_access_token and gitlab_username columns from sys_user table

DROP PROCEDURE IF EXISTS upgrade_v15_remove_git_config;

DELIMITER $$
CREATE PROCEDURE upgrade_v15_remove_git_config()
BEGIN
    IF EXISTS (
        SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'git_access_token'
    ) THEN
        ALTER TABLE sys_user DROP COLUMN git_access_token;
    END IF;

    IF EXISTS (
        SELECT * FROM information_schema.COLUMNS WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_user' AND COLUMN_NAME = 'gitlab_username'
    ) THEN
        ALTER TABLE sys_user DROP COLUMN gitlab_username;
    END IF;
END $$
DELIMITER ;

CALL upgrade_v15_remove_git_config();
DROP PROCEDURE IF EXISTS upgrade_v15_remove_git_config;
