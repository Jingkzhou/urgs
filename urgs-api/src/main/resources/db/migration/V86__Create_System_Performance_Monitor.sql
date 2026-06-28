DROP PROCEDURE IF EXISTS ExecuteIdempotent_V86;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V86()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_monitor_target_config'
    ) THEN
        CREATE TABLE `sys_monitor_target_config` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `target_type` VARCHAR(20) NOT NULL COMMENT 'SERVER/DATABASE',
            `target_id` BIGINT NOT NULL DEFAULT 0 COMMENT '0表示全局默认，其他值为目标ID',
            `enabled` TINYINT NOT NULL DEFAULT 1,
            `thresholds_json` JSON DEFAULT NULL,
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_monitor_target` (`target_type`, `target_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='性能监控目标配置';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_monitor_server_sample'
    ) THEN
        CREATE TABLE `sys_monitor_server_sample` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `asset_id` BIGINT NOT NULL,
            `collected_at` DATETIME(3) NOT NULL,
            `collection_state` VARCHAR(20) NOT NULL,
            `severity` VARCHAR(20) NOT NULL,
            `cpu_percent` DECIMAL(7,3) DEFAULT NULL,
            `load_one` DECIMAL(10,3) DEFAULT NULL,
            `memory_total_bytes` BIGINT DEFAULT NULL,
            `memory_used_bytes` BIGINT DEFAULT NULL,
            `memory_percent` DECIMAL(7,3) DEFAULT NULL,
            `disk_total_bytes` BIGINT DEFAULT NULL,
            `disk_used_bytes` BIGINT DEFAULT NULL,
            `disk_percent` DECIMAL(7,3) DEFAULT NULL,
            `disk_details_json` JSON DEFAULT NULL,
            `network_rx_bps` BIGINT DEFAULT NULL,
            `network_tx_bps` BIGINT DEFAULT NULL,
            `uptime_seconds` BIGINT DEFAULT NULL,
            `error_message` VARCHAR(500) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_monitor_server_asset_time` (`asset_id`, `collected_at`),
            KEY `idx_monitor_server_time` (`collected_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='服务器性能采样';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_monitor_db_sample'
    ) THEN
        CREATE TABLE `sys_monitor_db_sample` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `datasource_id` BIGINT NOT NULL,
            `collected_at` DATETIME(3) NOT NULL,
            `collection_state` VARCHAR(20) NOT NULL,
            `severity` VARCHAR(20) NOT NULL,
            `version` VARCHAR(100) DEFAULT NULL,
            `latency_ms` BIGINT DEFAULT NULL,
            `threads_connected` BIGINT DEFAULT NULL,
            `max_connections` BIGINT DEFAULT NULL,
            `threads_running` BIGINT DEFAULT NULL,
            `qps` DECIMAL(14,3) DEFAULT NULL,
            `tps` DECIMAL(14,3) DEFAULT NULL,
            `slow_queries` BIGINT DEFAULT NULL,
            `slow_sql_avg_latency_ms` DECIMAL(16,3) DEFAULT NULL,
            `buffer_pool_hit_percent` DECIMAL(7,3) DEFAULT NULL,
            `row_lock_waits` BIGINT DEFAULT NULL,
            `uptime_seconds` BIGINT DEFAULT NULL,
            `capabilities_json` JSON DEFAULT NULL,
            `error_message` VARCHAR(500) DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_monitor_db_datasource_time` (`datasource_id`, `collected_at`),
            KEY `idx_monitor_db_time` (`collected_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MySQL性能采样';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'sys_monitor_slow_sql_sample'
    ) THEN
        CREATE TABLE `sys_monitor_slow_sql_sample` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `datasource_id` BIGINT NOT NULL,
            `collected_at` DATETIME(3) NOT NULL,
            `digest` VARCHAR(128) NOT NULL,
            `digest_text` TEXT NOT NULL,
            `executions` BIGINT NOT NULL DEFAULT 0,
            `avg_latency_ms` DECIMAL(16,3) DEFAULT NULL,
            `total_latency_ms` DECIMAL(18,3) DEFAULT NULL,
            `rows_examined` BIGINT DEFAULT NULL,
            `rows_sent` BIGINT DEFAULT NULL,
            PRIMARY KEY (`id`),
            KEY `idx_monitor_slow_sql_datasource_time` (`datasource_id`, `collected_at`),
            KEY `idx_monitor_slow_sql_digest` (`datasource_id`, `digest`, `collected_at`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='MySQL慢SQL摘要采样';
    END IF;

    INSERT INTO `sys_monitor_target_config` (`target_type`, `target_id`, `enabled`, `thresholds_json`)
    SELECT 'SERVER', 0, 1,
           JSON_OBJECT('cpuWarning', 80, 'cpuCritical', 90,
                       'memoryWarning', 80, 'memoryCritical', 90,
                       'diskWarning', 80, 'diskCritical', 90,
                       'enabledMetrics', JSON_ARRAY('CPU', 'MEMORY', 'DISK', 'LOAD', 'NETWORK', 'UPTIME'))
    WHERE NOT EXISTS (
        SELECT 1 FROM `sys_monitor_target_config`
        WHERE `target_type` = 'SERVER' AND `target_id` = 0
    );

    INSERT INTO `sys_monitor_target_config` (`target_type`, `target_id`, `enabled`, `thresholds_json`)
    SELECT 'DATABASE', 0, 1,
           JSON_OBJECT('connectionWarning', 70, 'connectionCritical', 90,
                       'latencyWarning', 200, 'latencyCritical', 1000,
                       'slowSqlWarning', 1000, 'slowSqlCritical', 3000,
                       'lockWaitWarning', 1, 'lockWaitCritical', 5)
    WHERE NOT EXISTS (
        SELECT 1 FROM `sys_monitor_target_config`
        WHERE `target_type` = 'DATABASE' AND `target_id` = 0
    );

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '性能监控', 'sys:monitor', 'menu', '/ops/infra/monitor', 2,
           COALESCE(
               (SELECT `id` FROM `sys_permission` WHERE `code` = 'ops:infra:view' LIMIT 1),
               (SELECT `id` FROM `sys_permission` WHERE `code` = 'ops' LIMIT 1),
               (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys' LIMIT 1)
           )
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:monitor');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '查询', 'sys:monitor:query', 'button', '-', 3,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:monitor' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:monitor:query');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '阈值配置', 'sys:monitor:config', 'button', '-', 3,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:monitor' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:monitor:config');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '立即采集', 'sys:monitor:collect', 'button', '-', 3,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:monitor' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:monitor:collect');

    INSERT IGNORE INTO `sys_role_permission` (`role_id`, `perm_code`)
    SELECT 1, `code` FROM `sys_permission` WHERE `code` LIKE 'sys:monitor%';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V86();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V86;
