DROP PROCEDURE IF EXISTS ExecuteIdempotent_V85;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V85()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM `t_ai_agent`
        WHERE `agent_code` = 'general-agent'
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
            'general-agent',
            '通用助手',
            'GENERAL',
            '当没有专业 Agent 适合用户任务时使用，负责通用问答、需求澄清、方案说明和轻量代码建议。',
            '你是 URGS 平台的通用助手。没有专业 Agent 适合时，由你负责回答用户问题、澄清需求、给出通用方案和轻量代码建议。保持回答准确、简洁，涉及工作区文件时只读分析，不写入文件。',
            1,
            'DEEPAGENTS',
            '[]',
            '["通用问答","需求澄清","方案说明","轻量代码建议","未分类任务"]',
            '没有专业 Agent 匹配的任务\n用户只是在询问概念或方案\n用户需要先澄清需求\n简单问答或轻量代码建议',
            '/AGENTS.md',
            NULL,
            'ls,read_file,glob,grep',
            '{"write":"deny","execute":"deny"}',
            NULL,
            9999,
            NOW()
        );
    ELSE
        UPDATE `t_ai_agent`
        SET `status` = 1,
            `agent_type` = CASE WHEN `agent_type` IS NULL OR `agent_type` = '' THEN 'GENERAL' ELSE `agent_type` END,
            `build_mode` = CASE WHEN `build_mode` IS NULL OR `build_mode` = '' THEN 'DEEPAGENTS' ELSE `build_mode` END,
            `sort_order` = CASE WHEN `sort_order` IS NULL THEN 9999 ELSE `sort_order` END,
            `updated_at` = NOW()
        WHERE `agent_code` = 'general-agent';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V85();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V85;
