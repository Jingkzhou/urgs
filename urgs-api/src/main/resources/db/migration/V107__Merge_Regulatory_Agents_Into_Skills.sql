DROP PROCEDURE IF EXISTS ExecuteIdempotent_V107;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V107()
BEGIN
    DECLARE v_regulatory_agent_id BIGINT DEFAULT NULL;
    DECLARE v_legacy_data_agent_id BIGINT DEFAULT NULL;
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    SELECT MAX(`id`)
    INTO v_regulatory_agent_id
    FROM `t_ai_agent`
    WHERE `agent_code` = 'regulatory-knowledge-agent';

    SELECT MAX(`id`)
    INTO v_legacy_data_agent_id
    FROM `t_ai_agent`
    WHERE `agent_code` = 'regulatory-data-query-agent';

    IF v_regulatory_agent_id IS NOT NULL THEN
        UPDATE `t_ai_agent`
        SET `name` = '监管助手',
            `agent_type` = 'SPECIALIST',
            `description` = '面向监管报送业务的统一专业只读助手，通过监管知识查询和监管指标数据查询 Skill 回答制度口径、报表字段、校验关系、业务影响及受控指标数据问题。',
            `system_prompt` = '你是 URGS 平台统一的监管助手。你负责理解用户的监管业务目标，并在同一会话中选择合适的 Skill 完成任务。\n\nSkill 选择规则：\n1. 监管制度、系统、报表、字段口径、校验关系、业务场景、原文依据和监管影响评估，使用 regulatory-knowledge-query。\n2. 实际指标值、明细记录、可用期间、环比同比和变动贡献，使用 regulatory-data-query。\n3. 同时包含口径与数据的问题，先核对知识口径，再查询实际数据，最终合并回答。\n4. 不得用模型常识替代知识库证据，不得自行计算或编造指标数据，不得生成原始 SQL。\n5. 当前用户没有数据查询 Skill 权限时，仍可回答知识问题；涉及实际数据时明确说明权限不足，不得转交或伪装成另一个 Agent。',
            `status` = 1,
            `build_mode` = 'DEEPAGENTS',
            `prompts` = '[{"title":"查询报表口径","content":"请查询指定监管报表的报送范围、关键字段和口径，并列出知识库依据。"},{"title":"查询监管指标","content":"请查询指定机构和统计期间的监管指标数据。"},{"title":"分析指标变动","content":"请比较两个统计期间的监管指标变化，并结合监管口径解释。"},{"title":"评估监管影响","content":"请分析这个业务场景可能影响哪些监管系统、报表和指标，并说明依据。"}]',
            `capability_tags` = '["监管助手","监管报送","监管制度","监管系统","监管报表","字段口径","校验关系","业务场景","监管影响评估","监管指标","指标汇总","指标明细","指标对比","变动贡献"]',
            `routing_examples` = '用户询问监管制度、监管系统、监管报表、字段口径或校验关系\n用户评估新产品、新业务或系统改造对监管报送的影响\n用户查询指定机构和统计期间的监管指标汇总或明细\n用户比较监管指标的环比同比或分析变动贡献\n用户需要结合监管口径解释实际指标数据',
            `memory_files` = '/AGENTS.md',
            `skill_dirs` = '["regulatory-knowledge-query","regulatory-data-query"]',
            `tool_allowlist` = NULL,
            `updated_at` = NOW()
        WHERE `id` = v_regulatory_agent_id;
    END IF;

    IF v_regulatory_agent_id IS NOT NULL AND v_legacy_data_agent_id IS NOT NULL THEN
        INSERT INTO `t_ai_agent_role` (`agent_id`, `role_id`, `created_at`)
        SELECT v_regulatory_agent_id, legacy_role.`role_id`, NOW()
        FROM `t_ai_agent_role` legacy_role
        WHERE legacy_role.`agent_id` = v_legacy_data_agent_id
          AND NOT EXISTS (
              SELECT 1
              FROM `t_ai_agent_role` current_role
              WHERE current_role.`agent_id` = v_regulatory_agent_id
                AND current_role.`role_id` = legacy_role.`role_id`
          );

        UPDATE `ai_chat_session`
        SET `agent_id` = v_regulatory_agent_id
        WHERE `agent_id` = v_legacy_data_agent_id;

        UPDATE `ai_agent_run`
        SET `agent_id` = v_regulatory_agent_id,
            `agent_code` = 'regulatory-knowledge-agent'
        WHERE `agent_id` = v_legacy_data_agent_id
           OR `agent_code` = 'regulatory-data-query-agent';

        UPDATE `ai_agent_run_event`
        SET `agent_id` = v_regulatory_agent_id,
            `agent_code` = 'regulatory-knowledge-agent'
        WHERE `agent_id` = v_legacy_data_agent_id
           OR `agent_code` = 'regulatory-data-query-agent';

        UPDATE `ai_agent_tool_call`
        SET `agent_id` = v_regulatory_agent_id,
            `agent_code` = 'regulatory-knowledge-agent'
        WHERE `agent_id` = v_legacy_data_agent_id
           OR `agent_code` = 'regulatory-data-query-agent';

        DELETE FROM `t_ai_agent_role`
        WHERE `agent_id` = v_legacy_data_agent_id;

        DELETE FROM `t_ai_agent`
        WHERE `id` = v_legacy_data_agent_id;
    END IF;
END$$
DELIMITER ;

CALL ExecuteIdempotent_V107();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V107;
