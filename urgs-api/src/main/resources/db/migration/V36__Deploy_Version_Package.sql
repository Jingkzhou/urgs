-- V36__Deploy_Version_Package.sql
-- 创建版本包表和部署步骤逻辑

-- 1. 创建版本包表
CREATE TABLE `t_version_package` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
    `repo_id` BIGINT NOT NULL COMMENT '关联 Git 仓库 ID',
    `sso_id` BIGINT NOT NULL COMMENT '关联监管系统 ID',
    `version` VARCHAR(50) NOT NULL COMMENT '版本号',
    `git_ref` VARCHAR(100) COMMENT 'Git 引用 (Tag/Branch)',
    `commit_sha` VARCHAR(100) COMMENT 'Commit SHA',
    `package_name` VARCHAR(255) COMMENT '包名',
    `package_url` VARCHAR(500) COMMENT '包路径/地址',
    `package_size` BIGINT COMMENT '文件大小',
    `description` TEXT COMMENT '版本说明',
    `deploy_script` TEXT COMMENT '部署脚本内容',
    `rollback_script` TEXT COMMENT '回退脚本内容',
    `status` VARCHAR(20) DEFAULT 'draft' COMMENT '状态: draft, ready, deployed, archived',
    `created_by` BIGINT COMMENT '创建人',
    `deployed_by` BIGINT COMMENT '部署人',
    `deployed_at` DATETIME COMMENT '部署时间',
    `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX `idx_package_repo` (`repo_id`),
    INDEX `idx_package_sso` (`sso_id`),
    INDEX `idx_package_version` (`version`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='版本包记录表';

-- 3. 扩展 t_deployment 表
DROP PROCEDURE IF EXISTS AlterDeploymentForPackages;
DELIMITER $$
CREATE PROCEDURE AlterDeploymentForPackages()
BEGIN
    -- 增加 package_id
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_deployment'
        AND COLUMN_NAME = 'package_id'
    ) THEN
        ALTER TABLE `t_deployment` ADD COLUMN `package_id` BIGINT COMMENT '关联版本包ID' AFTER `version`;
    END IF;

    -- 增加 deploy_mode
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_deployment'
        AND COLUMN_NAME = 'deploy_mode'
    ) THEN
        ALTER TABLE `t_deployment` ADD COLUMN `deploy_mode` VARCHAR(20) DEFAULT 'full' COMMENT '部署模式: full, incremental' AFTER `package_id`;
    END IF;

    -- 增加 backup_path
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_deployment'
        AND COLUMN_NAME = 'backup_path'
    ) THEN
        ALTER TABLE `t_deployment` ADD COLUMN `backup_path` VARCHAR(500) COMMENT '生产备份路径' AFTER `artifact_url`;
    END IF;
END$$
DELIMITER ;
CALL AlterDeploymentForPackages();
DROP PROCEDURE AlterDeploymentForPackages;
