-- V15__Remove_Git_Config_From_User.sql
-- Remove git_access_token and gitlab_username columns from sys_user table

ALTER TABLE sys_user DROP COLUMN git_access_token;
ALTER TABLE sys_user DROP COLUMN gitlab_username;
