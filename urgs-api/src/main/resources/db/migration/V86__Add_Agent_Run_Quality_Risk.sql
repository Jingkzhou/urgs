DROP PROCEDURE IF EXISTS ExecuteIdempotent_V86;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V86()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_run' AND COLUMN_NAME = 'quality_risk'
    ) THEN
        ALTER TABLE `ai_agent_run`
            ADD COLUMN `quality_risk` TINYINT(1) DEFAULT 0 COMMENT '质量风险标记：0=正常，1=返工后仍未通过验收' AFTER `router_confidence`;
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V86();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V86;
