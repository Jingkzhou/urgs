-- Git 仓库生产投产包字段扩展

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V59;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V59()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'spec_path'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `spec_path` VARCHAR(255) COMMENT '发布规格文件路径' AFTER `env_id`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'package_type'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `package_type` VARCHAR(50) COMMENT '投产包类型: db/app/static/mixed' AFTER `spec_path`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'gate_status'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `gate_status` VARCHAR(20) COMMENT '门禁状态' AFTER `package_type`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'gate_summary'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `gate_summary` LONGTEXT COMMENT '门禁摘要(JSON)' AFTER `gate_status`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'changed_files'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `changed_files` LONGTEXT COMMENT '差异文件清单(JSON)' AFTER `gate_summary`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'build_log'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `build_log` LONGTEXT COMMENT '打包日志' AFTER `changed_files`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'deploy_command'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `deploy_command` VARCHAR(500) COMMENT '生产部署命令' AFTER `build_log`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'rollback_command'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `rollback_command` VARCHAR(500) COMMENT '生产回滚命令' AFTER `deploy_command`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_version_package'
        AND COLUMN_NAME = 'backup_status'
    ) THEN
        ALTER TABLE `t_version_package`
            ADD COLUMN `backup_status` VARCHAR(20) COMMENT '备份状态' AFTER `rollback_command`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V59();
DROP PROCEDURE ExecuteIdempotent_V59;
