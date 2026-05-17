-- V62__Add_Metric_Chart_Config.sql
-- 首页指标走势配置增强：每个系统/指标类型可配置支持图形和默认图形。

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V62;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V62()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_metric_type'
          AND COLUMN_NAME = 'default_chart_type'
    ) THEN
        ALTER TABLE `t_metric_type`
            ADD COLUMN `default_chart_type` VARCHAR(32) NOT NULL DEFAULT 'area' COMMENT '默认图形类型：line/area/bar/pie' AFTER `color`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_metric_type'
          AND COLUMN_NAME = 'supported_chart_types'
    ) THEN
        ALTER TABLE `t_metric_type`
            ADD COLUMN `supported_chart_types` VARCHAR(128) NOT NULL DEFAULT 'area,line,bar' COMMENT '支持图形类型，英文逗号分隔' AFTER `default_chart_type`;
    END IF;

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '首页指标走势配置', 'sys:metric', 'menu', '/admin/metric', 1,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:metric');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '查询', 'sys:metric:query', 'button', '-', 2,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:metric' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:metric:query');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '新增', 'sys:metric:add', 'button', '-', 2,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:metric' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:metric:add');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '编辑', 'sys:metric:edit', 'button', '-', 2,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:metric' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:metric:edit');

    INSERT INTO `sys_permission` (`name`, `code`, `type`, `path`, `level`, `parent_id`)
    SELECT '删除', 'sys:metric:del', 'button', '-', 2,
           (SELECT `id` FROM `sys_permission` WHERE `code` = 'sys:metric' LIMIT 1)
    WHERE NOT EXISTS (SELECT 1 FROM `sys_permission` WHERE `code` = 'sys:metric:del');

    INSERT IGNORE INTO `sys_role_permission` (`role_id`, `perm_code`)
    SELECT 1, `code` FROM `sys_permission` WHERE `code` LIKE 'sys:metric%';
END$$
DELIMITER ;
CALL ExecuteIdempotent_V62();
DROP PROCEDURE ExecuteIdempotent_V62;
