DROP PROCEDURE IF EXISTS ExecuteIdempotent_V88;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V88()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM `t_ai_agent`
        WHERE `agent_code` = 'regulatory-data-query-agent'
    ) THEN
        INSERT INTO `t_ai_agent` (
            `agent_code`,
            `name`,
            `agent_type`,
            `description`,
            `system_prompt`,
            `status`,
            `build_mode`,
            `prompts`,
            `capability_tags`,
            `routing_examples`,
            `memory_files`,
            `skill_dirs`,
            `tool_allowlist`,
            `policy_config`,
            `model_config`,
            `sort_order`,
            `updated_at`
        ) VALUES (
            'regulatory-data-query-agent',
            '监管指标数据查询助手',
            'SPECIALIST',
            '直接通过监管查询 Skill 读取固定 MySQL 汇总表和明细表；只支持受控的监管指标查询。',
            '你是监管指标数据查询助手。所有查询规则、工具和数据范围均由 regulatory-data-query Skill 定义，严格遵循该 Skill。',
            0,
            'DEEPAGENTS',
            '[]',
            '["监管指标","指标汇总","指标明细","监管数据查询"]',
            '查询某监管指标的汇总数据\n查询某监管指标的明细记录\n查看某日期和机构范围内的监管指标',
            NULL,
            '["regulatory-data-query"]',
            NULL,
            '{"write":"deny","execute":"deny"}',
            NULL,
            110,
            NOW()
        );
    ELSE
        UPDATE `t_ai_agent`
        SET `status` = 0,
            `agent_type` = 'SPECIALIST',
            `build_mode` = 'DEEPAGENTS',
            `skill_dirs` = '["regulatory-data-query"]',
            `tool_allowlist` = NULL,
            `policy_config` = '{"write":"deny","execute":"deny"}',
            `updated_at` = NOW()
        WHERE `agent_code` = 'regulatory-data-query-agent';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V88();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V88;
