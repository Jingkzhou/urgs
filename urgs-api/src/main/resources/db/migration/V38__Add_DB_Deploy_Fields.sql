-- V38__Add_DB_Deploy_Fields.sql
-- 数据库自动化部署所需的字段扩展:
-- 1. t_version_package: 基线版本信息 + 目标服务器 + 执行用户
-- 2. t_infrastructure_asset: 数据库连接字段 (端口/库名/服务名)
-- 3. t_infrastructure_user: 用户类型 (os/db)

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V38;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V38()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    -- ===== t_version_package 扩展 =====

    -- 基线 Git 引用 (上一版本 Tag)
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'previous_git_ref'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `previous_git_ref` VARCHAR(100) COMMENT '基线 Git 引用 (上一版本 Tag)' AFTER `commit_sha`;
    END IF;

    -- 基线 Commit SHA
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'previous_commit_sha'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `previous_commit_sha` VARCHAR(100) COMMENT '基线 Commit SHA' AFTER `previous_git_ref`;
    END IF;

    -- 目标数据库服务器资产 ID
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'asset_id'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `asset_id` BIGINT COMMENT '目标数据库服务器资产 ID' AFTER `status`;
    END IF;

    -- 执行用户 (数据库用户名)
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'exec_user'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `exec_user` VARCHAR(100) COMMENT '执行用户 (数据库用户名)' AFTER `asset_id`;
    END IF;

    -- ===== t_infrastructure_asset 扩展 =====

    -- 数据库端口
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_asset'
        AND COLUMN_NAME = 'db_port'
    ) THEN
        ALTER TABLE `t_infrastructure_asset`
            ADD COLUMN `db_port` INT COMMENT '数据库端口 (Oracle:1521, MySQL:3306)' AFTER `db_type`;
    END IF;

    -- 数据库名/Schema/SID
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_asset'
        AND COLUMN_NAME = 'db_name'
    ) THEN
        ALTER TABLE `t_infrastructure_asset`
            ADD COLUMN `db_name` VARCHAR(100) COMMENT '数据库名/Schema/SID' AFTER `db_port`;
    END IF;

    -- Oracle 服务名
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_asset'
        AND COLUMN_NAME = 'db_service_name'
    ) THEN
        ALTER TABLE `t_infrastructure_asset`
            ADD COLUMN `db_service_name` VARCHAR(100) COMMENT 'Oracle 服务名 (与 SID 二选一)' AFTER `db_name`;
    END IF;

    -- ===== t_infrastructure_user 扩展 =====

    -- 用户类型: os(操作系统) / db(数据库)
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_user'
        AND COLUMN_NAME = 'user_type'
    ) THEN
        ALTER TABLE `t_infrastructure_user`
            ADD COLUMN `user_type` VARCHAR(20) DEFAULT 'os' COMMENT '用户类型: os(操作系统)/db(数据库)' AFTER `password`;
    END IF;

END$$
DELIMITER ;
CALL ExecuteIdempotent_V38();
DROP PROCEDURE ExecuteIdempotent_V38;
