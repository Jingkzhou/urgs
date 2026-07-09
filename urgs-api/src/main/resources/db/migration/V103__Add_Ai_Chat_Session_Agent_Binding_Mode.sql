DROP PROCEDURE IF EXISTS ExecuteIdempotent_V103;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V103()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'ai_chat_session'
          AND COLUMN_NAME = 'agent_binding_mode'
    ) THEN
        ALTER TABLE `ai_chat_session`
            ADD COLUMN `agent_binding_mode` VARCHAR(16) DEFAULT NULL COMMENT 'Agent绑定模式: MANUAL用户选择 AUTO自动路由' AFTER `agent_id`;
    END IF;

    UPDATE `ai_chat_session`
    SET `agent_binding_mode` = 'MANUAL'
    WHERE `agent_id` IS NOT NULL
      AND (`agent_binding_mode` IS NULL OR `agent_binding_mode` = '');
END$$
DELIMITER ;

CALL ExecuteIdempotent_V103();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V103;
