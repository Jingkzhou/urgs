DROP PROCEDURE IF EXISTS ExecuteIdempotent_V75;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V75()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
    ) AND NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND COLUMN_NAME = 'app_code'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill`
            ADD COLUMN `app_code` VARCHAR(64) NOT NULL DEFAULT 'hermesagent' COMMENT 'Agent App CLI编码' AFTER `id`;
    END IF;

    UPDATE `t_ai_agent_app_skill`
    SET `app_code` = 'hermesagent'
    WHERE `app_code` IS NULL OR `app_code` = '';

    IF EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'uk_agent_app_skill_agent_code'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill` DROP INDEX `uk_agent_app_skill_agent_code`;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'idx_agent_app_skill_agent_status'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill` DROP INDEX `idx_agent_app_skill_agent_status`;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'uk_agent_app_skill_code'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill` DROP INDEX `uk_agent_app_skill_code`;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'idx_agent_app_skill_status'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill` DROP INDEX `idx_agent_app_skill_status`;
    END IF;

    IF EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND COLUMN_NAME = 'agent_id'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill` DROP COLUMN `agent_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'uk_agent_app_skill_app_code'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill`
            ADD UNIQUE KEY `uk_agent_app_skill_app_code` (`app_code`, `code`);
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent_app_skill'
          AND INDEX_NAME = 'idx_agent_app_skill_status'
    ) THEN
        ALTER TABLE `t_ai_agent_app_skill`
            ADD KEY `idx_agent_app_skill_status` (`app_code`, `status`, `sort_order`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V75();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V75;
