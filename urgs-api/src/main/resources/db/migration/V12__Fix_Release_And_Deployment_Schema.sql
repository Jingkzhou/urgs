-- V12__Fix_Release_And_Deployment_Schema.sql
-- 修复 t_deployment 和 t_release_record 缺少字段的问题

-- 1. 为 t_deployment 增加 strategy_id 字段
DROP PROCEDURE IF EXISTS AddStrategyIdToDeployment;
DELIMITER $$
CREATE PROCEDURE AddStrategyIdToDeployment()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_deployment'
        AND COLUMN_NAME = 'strategy_id'
    ) THEN
        ALTER TABLE `t_deployment` ADD COLUMN `strategy_id` BIGINT COMMENT '发布策略ID' AFTER `env_id`;
    END IF;
END$$
DELIMITER ;
CALL AddStrategyIdToDeployment();
DROP PROCEDURE AddStrategyIdToDeployment;

-- 2. 为 t_release_record 增加缺失字段
DROP PROCEDURE IF EXISTS FixReleaseRecordColumns;
DELIMITER $$
CREATE PROCEDURE FixReleaseRecordColumns()
BEGIN
    -- 增加 change_list
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_release_record'
        AND COLUMN_NAME = 'change_list'
    ) THEN
        ALTER TABLE `t_release_record` ADD COLUMN `change_list` TEXT COMMENT '变更内容列表 (JSON)' AFTER `description`;
    END IF;

    -- 增加 deployment_id
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_release_record'
        AND COLUMN_NAME = 'deployment_id'
    ) THEN
        ALTER TABLE `t_release_record` ADD COLUMN `deployment_id` BIGINT COMMENT '关联部署记录ID' AFTER `change_list`;
    END IF;
END$$
DELIMITER ;
CALL FixReleaseRecordColumns();
DROP PROCEDURE FixReleaseRecordColumns;
