-- V19__Add_CreateBy_To_GitRepository.sql

-- 1. 添加 create_by 字段
DROP PROCEDURE IF EXISTS upgrade_v19_git_repository;
DELIMITER $$
CREATE PROCEDURE upgrade_v19_git_repository()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS 
        WHERE TABLE_SCHEMA = DATABASE() 
        AND TABLE_NAME = 't_git_repository' 
        AND COLUMN_NAME = 'create_by'
    ) THEN
        ALTER TABLE t_git_repository ADD COLUMN create_by BIGINT COMMENT '创建人用户ID';
        -- 添加索引以优化查询
        CREATE INDEX idx_git_repo_create_by ON t_git_repository(create_by);
    END IF;
END $$
DELIMITER ;

CALL upgrade_v19_git_repository();
DROP PROCEDURE IF EXISTS upgrade_v19_git_repository;

-- 2. 补全存量数据的创建人（可选，默认设置为管理员 ID 1）
UPDATE t_git_repository SET create_by = 1 WHERE create_by IS NULL;
