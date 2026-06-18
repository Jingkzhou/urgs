DROP PROCEDURE IF EXISTS ExecuteIdempotent_V87;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V87()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM `t_ai_agent`
        WHERE `agent_code` = 'regulatory-knowledge-agent'
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
            'regulatory-knowledge-agent',
            '监管知识库助手',
            'SPECIALIST',
            '负责监管报送知识库的入库、查询、巡检与修复，遵循知识库 AGENTS.md 的目录分工、检索策略和闭环机制。',
            '你是 URGS 平台的监管知识库助手，维护一个结构化监管知识库。开始任何工作前，必须读取知识库根目录的 AGENTS.md 并严格遵循其约束。\n\n核心职责：\n1. Ingest：新增资料时按 AGENTS.md 的 ingest 流程入库，原文页忠实转录，结论回写知识页，不覆盖旧原文正文。\n2. Query：回答监管类问题时按 L0→L1→L2→L3 逐层检索，形成候选集并二次复检，区分已知结论、依据来源、推断判断、待确认。\n3. Lint：巡检结构、路由、知识层问题，分级修复，可自动修的直接修，涉及口径判断的转入待确认清单。\n4. Fix：修复格式、链接、索引、命名等结构问题，产生可复用检查项时回写验收清单。\n\n硬约束：\n- 原文页（01-资料库/ 下含 -原文 的文件）只忠实转录，不得摘要化改写、省略字段行列、合并段落或补入原文没有的解释。\n- 去冗余：资料页写来源与核心观点，主题页写稳定结论，综合页写跨页判断，项目页写推进状态，不重复单页摘要。\n- 监管类 query 必须覆盖监管影响维度矩阵（客户/交易对手、产品/协议、账户、交易、余额、流动性期限、LCR/NSFR、集中度、利率重定价、国别、资本等），排除项要写依据。\n- 一次有效工作至少落到证据层/知识层/队列层/日志层中的 2 层以上，结束时记录到 05-日志/log.md。\n- 不确定内容显式标注 待确认，写入 04-综合/待确认清单.md，不静默跳过。\n- 优先更新已有页面，不新建近义页面；同一结论已有承接页就补该页。',
            0,
            'DEEPAGENTS',
            '[]',
            '["监管报送","监管知识库","资料入库","ingest","监管查询","监管巡检","知识库修复","报表口径","血缘分析","报表校验关系"]',
            '用户要入库监管原文或数据字典\n用户询问某报表的字段口径、校验关系、报送范围\n用户要做监管报送影响评估或业务场景映射\n用户要求巡检或修复知识库结构\n用户提到 监管系统、报表编码、监管报送 这类词',
            NULL,
            NULL,
            'ls,read_file,glob,grep',
            '{"write":"deny","execute":"deny","requires_workspace_root":true}',
            NULL,
            100,
            NOW()
        );
    ELSE
        UPDATE `t_ai_agent`
        SET `status` = CASE
                WHEN `policy_config` REGEXP '"workspace_root"[[:space:]]*:' THEN `status`
                ELSE 0
            END,
            `agent_type` = 'SPECIALIST',
            `build_mode` = 'DEEPAGENTS',
            `updated_at` = NOW()
        WHERE `agent_code` = 'regulatory-knowledge-agent';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V87();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V87;
