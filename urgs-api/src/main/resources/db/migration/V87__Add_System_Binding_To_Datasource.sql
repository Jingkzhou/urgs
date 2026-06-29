DROP PROCEDURE IF EXISTS ExecuteIdempotent_V87;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V87()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_datasource_config'
          AND COLUMN_NAME = 'app_system_id'
    ) THEN
        ALTER TABLE `sys_datasource_config`
            ADD COLUMN `app_system_id` BIGINT NULL COMMENT '关联系统ID' AFTER `connection_params`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_datasource_config'
          AND COLUMN_NAME = 'env_id'
    ) THEN
        ALTER TABLE `sys_datasource_config`
            ADD COLUMN `env_id` BIGINT NULL COMMENT '关联环境ID' AFTER `app_system_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_datasource_config'
          AND INDEX_NAME = 'idx_datasource_system_env'
    ) THEN
        ALTER TABLE `sys_datasource_config`
            ADD KEY `idx_datasource_system_env` (`app_system_id`, `env_id`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V87();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V87;
