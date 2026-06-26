DROP PROCEDURE IF EXISTS ExecuteIdempotent_V84;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V84()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_datasource_pool'
    ) THEN
        CREATE TABLE `sys_datasource_pool` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `name` VARCHAR(100) NOT NULL COMMENT '数据池名称',
            `pool_type` VARCHAR(32) NOT NULL DEFAULT 'MIXED' COMMENT '数据池类型：SQL/SHELL/MIXED',
            `strategy` VARCHAR(32) NOT NULL DEFAULT 'LEAST_RUNNING' COMMENT '分配规则：LEAST_RUNNING/ROUND_ROBIN/WEIGHTED_ROUND_ROBIN',
            `status` TINYINT NOT NULL DEFAULT 1 COMMENT '状态：1启用，0停用',
            `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_datasource_pool_name` (`name`),
            KEY `idx_datasource_pool_status` (`status`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据源执行池';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'sys_datasource_pool_member'
    ) THEN
        CREATE TABLE `sys_datasource_pool_member` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `pool_id` BIGINT NOT NULL COMMENT '数据池ID',
            `datasource_id` BIGINT NOT NULL COMMENT '数据源ID',
            `enabled` TINYINT NOT NULL DEFAULT 1 COMMENT '是否启用',
            `weight` INT NOT NULL DEFAULT 1 COMMENT '权重',
            `max_concurrency` INT DEFAULT NULL COMMENT '最大并发，空表示不限制',
            `sort_no` INT NOT NULL DEFAULT 0 COMMENT '排序号',
            `remark` VARCHAR(500) DEFAULT NULL COMMENT '备注',
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_pool_datasource` (`pool_id`, `datasource_id`),
            KEY `idx_pool_member_pool` (`pool_id`, `enabled`, `sort_no`),
            KEY `idx_pool_member_datasource` (`datasource_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='数据源执行池成员';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task'
          AND COLUMN_NAME = 'datasource_pool_id'
    ) THEN
        ALTER TABLE `t_quartz_task`
            ADD COLUMN `datasource_pool_id` BIGINT NULL COMMENT '数据源执行池ID' AFTER `datasource_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task'
          AND INDEX_NAME = 'idx_quartz_task_datasource_pool_id'
    ) THEN
        ALTER TABLE `t_quartz_task`
            ADD KEY `idx_quartz_task_datasource_pool_id` (`datasource_pool_id`);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
          AND COLUMN_NAME = 'execute_pool_id'
    ) THEN
        ALTER TABLE `t_quartz_task_status`
            ADD COLUMN `execute_pool_id` BIGINT NULL COMMENT '本次执行选择的数据池ID' AFTER `msg`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
          AND COLUMN_NAME = 'execute_pool_name'
    ) THEN
        ALTER TABLE `t_quartz_task_status`
            ADD COLUMN `execute_pool_name` VARCHAR(100) NULL COMMENT '本次执行选择的数据池名称' AFTER `execute_pool_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
          AND COLUMN_NAME = 'execute_datasource_id'
    ) THEN
        ALTER TABLE `t_quartz_task_status`
            ADD COLUMN `execute_datasource_id` BIGINT NULL COMMENT '本次执行选择的数据源ID' AFTER `execute_pool_name`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
          AND COLUMN_NAME = 'execute_datasource_name'
    ) THEN
        ALTER TABLE `t_quartz_task_status`
            ADD COLUMN `execute_datasource_name` VARCHAR(100) NULL COMMENT '本次执行选择的数据源名称' AFTER `execute_datasource_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
          AND INDEX_NAME = 'idx_status_execute_datasource'
    ) THEN
        ALTER TABLE `t_quartz_task_status`
            ADD KEY `idx_status_execute_datasource` (`status`, `execute_datasource_id`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V84();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V84;
