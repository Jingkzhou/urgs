DROP PROCEDURE IF EXISTS ExecuteIdempotent_V60;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V60()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_task_realtime_monitor'
    ) THEN
        CREATE TABLE `t_task_realtime_monitor` (
            `id` BIGINT NOT NULL AUTO_INCREMENT,
            `system_code` VARCHAR(50) NOT NULL COMMENT '对应系统表的 AppID (client_id)',
            `task_name` VARCHAR(200) NOT NULL COMMENT '任务名称',
            `task_status` VARCHAR(20) NOT NULL COMMENT '状态: RUNNING, SUCCESS, FAILED',
            `start_time` DATETIME DEFAULT NULL COMMENT '任务开始时间',
            `end_time` DATETIME DEFAULT NULL COMMENT '任务完成时间',
            `data_date` DATE NOT NULL COMMENT '数据日期 (业务日期)',
            PRIMARY KEY (`id`),
            KEY `idx_task_realtime_start_time` (`start_time`),
            KEY `idx_task_realtime_system_time` (`system_code`, `start_time`),
            KEY `idx_task_realtime_data_date` (`data_date`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='实时任务监控明细表';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_status'
    ) THEN
        CREATE TABLE `t_quartz_task_status` (
            `plan_id` INT(11) NOT NULL,
            `data_date` VARCHAR(10) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
            `status` INT(11) DEFAULT NULL,
            `begin_time` DATETIME DEFAULT NULL,
            `update_time` DATETIME DEFAULT NULL,
            `end_time` DATETIME DEFAULT NULL,
            `msg` VARCHAR(2000) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci DEFAULT NULL,
            `id` INT(11) NOT NULL AUTO_INCREMENT,
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
            `create_date` VARCHAR(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci NOT NULL,
            PRIMARY KEY (`id`, `data_date`, `create_date`) USING BTREE,
            KEY `create_time` (`create_time`) USING BTREE,
            KEY `crt_time_plan_status` (`data_date`, `plan_id`, `status`) USING BTREE,
            KEY `idx_plan_data_date` (`plan_id`, `data_date`) USING BTREE,
            KEY `idx_data_date_status_plan` (`data_date`, `status`, `plan_id`) USING BTREE,
            KEY `idx_create_date_status` (`create_date`, `status`) USING BTREE,
            KEY `idx_create_date_update_time` (`create_date`, `update_time`) USING BTREE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci ROW_FORMAT=DYNAMIC
        PARTITION BY RANGE COLUMNS (`create_date`) (
            PARTITION `p_max` VALUES LESS THAN (MAXVALUE)
        );
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V60();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V60;
