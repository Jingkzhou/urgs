DROP PROCEDURE IF EXISTS ExecuteIdempotent_V109;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V109()
BEGIN
    DECLARE v_agent_id BIGINT DEFAULT NULL;
    DECLARE CONTINUE HANDLER FOR NOT FOUND SET v_agent_id = NULL;

    IF NOT EXISTS (
        SELECT 1
        FROM `t_ai_agent`
        WHERE `agent_code` = 'regulatory-market-assistant-agent'
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
            'regulatory-market-assistant-agent',
            '监管集市智能助手',
            'SPECIALIST',
            '咨询监管集市的表、字段、码值和业务口径，或基于已确认资产设计指标并生成经过静态校验的 SQL 草稿。',
            '你是监管集市智能助手。咨询和指标开发的工作流、工具边界、证据要求及输出格式均由 regulatory-market-assistant Skill 定义，必须严格遵循该 Skill。',
            1,
            'DEEPAGENTS',
            '[{"title":"咨询表和字段","content":"我想了解监管集市中与贷款余额相关的表、字段和码值，请说明可以如何使用。"},{"title":"开发监管指标","content":"我想基于监管集市开发一个指标，请先帮我梳理需求、定位资产并形成指标设计卡。"}]',
            '["监管集市","表字段咨询","码值查询","指标设计","SQL生成","SQL静态校验"]',
            '查询监管集市中某个业务概念对应哪些表和字段\n解释监管字段的业务口径、码值或物理绑定\n判断监管集市是否支持开发某个指标\n基于监管集市资产设计指标并生成 SQL 草稿\n校验指标 SQL 使用的表、字段和码值',
            NULL,
            '["regulatory-market-assistant"]',
            NULL,
            '{"write":"deny","execute":"deny"}',
            NULL,
            105,
            NOW()
        );
    ELSE
        UPDATE `t_ai_agent`
        SET `name` = '监管集市智能助手',
            `agent_type` = 'SPECIALIST',
            `description` = '咨询监管集市的表、字段、码值和业务口径，或基于已确认资产设计指标并生成经过静态校验的 SQL 草稿。',
            `system_prompt` = '你是监管集市智能助手。咨询和指标开发的工作流、工具边界、证据要求及输出格式均由 regulatory-market-assistant Skill 定义，必须严格遵循该 Skill。',
            `status` = 1,
            `build_mode` = 'DEEPAGENTS',
            `prompts` = '[{"title":"咨询表和字段","content":"我想了解监管集市中与贷款余额相关的表、字段和码值，请说明可以如何使用。"},{"title":"开发监管指标","content":"我想基于监管集市开发一个指标，请先帮我梳理需求、定位资产并形成指标设计卡。"}]',
            `capability_tags` = '["监管集市","表字段咨询","码值查询","指标设计","SQL生成","SQL静态校验"]',
            `routing_examples` = '查询监管集市中某个业务概念对应哪些表和字段\n解释监管字段的业务口径、码值或物理绑定\n判断监管集市是否支持开发某个指标\n基于监管集市资产设计指标并生成 SQL 草稿\n校验指标 SQL 使用的表、字段和码值',
            `memory_files` = NULL,
            `skill_dirs` = '["regulatory-market-assistant"]',
            `tool_allowlist` = NULL,
            `policy_config` = '{"write":"deny","execute":"deny"}',
            `sort_order` = 105,
            `updated_at` = NOW()
        WHERE `agent_code` = 'regulatory-market-assistant-agent';
    END IF;

    SELECT MAX(`id`)
    INTO v_agent_id
    FROM `t_ai_agent`
    WHERE `agent_code` = 'regulatory-market-assistant-agent';

    IF v_agent_id IS NOT NULL THEN
        INSERT INTO `t_ai_agent_role` (`agent_id`, `role_id`, `created_at`)
        SELECT v_agent_id, role_permission.`role_id`, NOW()
        FROM `sys_role_permission` role_permission
        WHERE role_permission.`perm_code` = 'ai:regulatory-query:use'
          AND NOT EXISTS (
              SELECT 1
              FROM `t_ai_agent_role` agent_role
              WHERE agent_role.`agent_id` = v_agent_id
                AND agent_role.`role_id` = role_permission.`role_id`
          );
    END IF;
END$$
DELIMITER ;

CALL ExecuteIdempotent_V109();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V109;
