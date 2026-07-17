DROP PROCEDURE IF EXISTS ExecuteIdempotent_V113;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V113()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_ai_agent'
          AND COLUMN_NAME = 'build_mode'
    ) THEN
        UPDATE `t_ai_agent`
        SET `build_mode` = 'DIRECT'
        WHERE `build_mode` IS NULL
           OR TRIM(`build_mode`) = ''
           OR UPPER(`build_mode`) NOT IN ('DIRECT', 'DIFY', 'AGENT_APP');

        ALTER TABLE `t_ai_agent`
            MODIFY COLUMN `build_mode` VARCHAR(32) DEFAULT 'DIRECT'
                COMMENT '助手构建方式: DIRECT模型直连 DIFY引擎 AGENT_APP工具编排';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V113();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V113;
