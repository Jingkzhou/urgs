-- V41__Create_Metric_Tables.sql
-- 指标走势功能:
-- 1. t_metric_type: 指标类型定义表（按系统维度）
-- 2. t_metric_data: 指标数据表（外部系统直接 INSERT 灌入）

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V41;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V41()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    -- ===== 指标类型定义表 =====
    CREATE TABLE IF NOT EXISTS `t_metric_type` (
        `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
        `system_id` VARCHAR(64) NOT NULL COMMENT '对应 sys_system.client_id',
        `type_code` VARCHAR(64) NOT NULL COMMENT '指标编码（如 txn_volume）',
        `type_name` VARCHAR(128) NOT NULL COMMENT '显示名称（如 交易量）',
        `unit` VARCHAR(32) DEFAULT NULL COMMENT '单位（如 笔, ms, %）',
        `color` VARCHAR(32) DEFAULT NULL COMMENT '图表颜色（如 #ef4444）',
        `sort_order` INT DEFAULT 0 COMMENT '排序',
        `status` TINYINT DEFAULT 1 COMMENT '1=启用, 0=禁用',
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
        `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        UNIQUE KEY `uk_system_type` (`system_id`, `type_code`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='指标类型定义';

    -- ===== 指标数据表 =====
    CREATE TABLE IF NOT EXISTS `t_metric_data` (
        `id` BIGINT AUTO_INCREMENT PRIMARY KEY,
        `system_id` VARCHAR(64) NOT NULL COMMENT '所属系统',
        `type_code` VARCHAR(64) NOT NULL COMMENT '指标编码',
        `metric_value` DECIMAL(20,4) NOT NULL COMMENT '指标值',
        `metric_time` DATETIME NOT NULL COMMENT '指标时间',
        `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP,
        KEY `idx_system_type_time` (`system_id`, `type_code`, `metric_time`),
        KEY `idx_metric_time` (`metric_time`)
    ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='指标数据（外部系统灌入）';

END$$
DELIMITER ;
CALL ExecuteIdempotent_V41();
DROP PROCEDURE ExecuteIdempotent_V41;
