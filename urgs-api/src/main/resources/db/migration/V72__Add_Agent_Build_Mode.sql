DROP PROCEDURE IF EXISTS ExecuteIdempotent_V72;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V72()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent'
          AND COLUMN_NAME = 'build_mode'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `build_mode` VARCHAR(32) DEFAULT 'RAG' COMMENT '助手构建方式: DIFY RAG AGENT_APP' AFTER `status`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent'
          AND COLUMN_NAME = 'agent_app_tools'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `agent_app_tools` TEXT DEFAULT NULL COMMENT 'Agent App允许调用的CLI工具JSON列表' AFTER `dify_api_base`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V72();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V72;
