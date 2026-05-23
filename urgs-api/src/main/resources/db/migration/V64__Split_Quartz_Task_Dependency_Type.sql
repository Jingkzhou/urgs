DROP PROCEDURE IF EXISTS ExecuteIdempotent_V64;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V64()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_dependency'
          AND COLUMN_NAME = 'dependency_type'
    ) THEN
        ALTER TABLE `t_quartz_task_dependency`
            ADD COLUMN `dependency_type` VARCHAR(16) NOT NULL DEFAULT 'DATA' COMMENT '依赖类型：DATA 数据依赖，CONTROL 控制依赖' AFTER `pre_task_id`;
    END IF;

    UPDATE `t_quartz_task_dependency`
    SET `dependency_type` = 'DATA'
    WHERE `dependency_type` IS NULL OR `dependency_type` = '';

    IF EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_dependency'
          AND INDEX_NAME = 'uk_task_pre'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_dependency'
          AND INDEX_NAME = 'uk_task_pre_type'
    ) THEN
        ALTER TABLE `t_quartz_task_dependency` DROP INDEX `uk_task_pre`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_dependency'
          AND INDEX_NAME = 'uk_task_pre_type'
    ) THEN
        ALTER TABLE `t_quartz_task_dependency`
            ADD UNIQUE KEY `uk_task_pre_type` (`task_id`, `pre_task_id`, `dependency_type`) USING BTREE;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_quartz_task_dependency'
          AND INDEX_NAME = 'idx_dependency_type'
    ) THEN
        ALTER TABLE `t_quartz_task_dependency`
            ADD KEY `idx_dependency_type` (`dependency_type`) USING BTREE;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V64();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V64;
