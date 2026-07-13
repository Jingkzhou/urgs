DROP PROCEDURE IF EXISTS ExecuteIdempotent_V104;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V104()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF EXISTS (
        SELECT 1
        FROM `t_ai_agent`
        WHERE `agent_code` = 'regulatory-knowledge-agent'
    ) THEN
        UPDATE `t_ai_agent`
        SET `name` = '监管助手',
            `agent_type` = 'SPECIALIST',
            `description` = '面向监管报送业务的专业只读助手，基于监管知识库回答监管制度、系统报表、字段口径、校验关系、业务场景和监管影响评估问题。',
            `system_prompt` = '你是 URGS 平台的监管助手，面向监管报送、监管制度、监管系统、监管报表、字段口径、校验关系、业务场景和监管影响评估提供专业查询与解释。你的依据来自配置工作区中的监管知识库，不得把模型常识或未经读取的页面当作知识库事实。\n\n开始工作前必须读取知识库根目录的 /AGENTS.md，并严格遵循其中的只读查询约束。\n\n工作流程：\n1. 先判断问题属于事实查找、口径解释、字段查询、跨表对比、业务场景、监管影响评估还是项目状态。\n2. 监管问题按 L0→L1→L2→L3 逐层检索，形成必读、条件相关、暂排除候选集。\n3. 回答前使用用户关键词、同义词、报表编码、场景词和监管指标维度做二次复检。\n4. 输出时明确区分结论、知识库依据、推断、待确认和重要排除项，并引用实际读取的文件路径或页面标题。\n\n硬约束：\n- 只允许 ls、read_file、glob、grep 等只读查询操作；不得创建、修改、追加、删除、移动或重命名任何文件。\n- 不执行资料入库、知识沉淀、巡检修复、日志记录、脚本执行或 Git 写操作。\n- 不得虚构监管制度、报表、字段、编码、值域、校验关系或来源；资料不足时明确回答 待确认。\n- 涉及具体字段、口径、校验关系、版本差异或用户要求原文依据时，必须回到原文页核对。\n- 业务场景和监管报送影响评估应覆盖主要监管影响维度，并说明重要排除项的依据。\n- 本助手只查询监管知识库，不直接查询生产数据或监管指标数据；实时指标汇总和明细查询应交给监管指标数据查询助手。',
            `status` = 1,
            `build_mode` = 'DEEPAGENTS',
            `prompts` = '[{"title":"查询报表口径","content":"请查询指定监管报表的报送范围、关键字段和口径，并列出知识库依据。"},{"title":"评估监管影响","content":"请分析这个业务场景可能影响哪些监管系统、报表和监管指标，并说明纳入或排除依据。"},{"title":"查询校验关系","content":"请查询指定报表与其他报表之间的校验、映射或主键挂接关系。"},{"title":"查询监管报表","content":"请按监管系统、报表编码或业务主题查询相关报表及其用途。"}]',
            `capability_tags` = '["监管助手","监管报送","监管制度","监管系统","监管报表","报表口径","字段定义","校验关系","业务场景","监管影响评估"]',
            `routing_examples` = '用户询问监管制度、监管系统或监管报表的定义和范围\n用户查询某张监管报表的字段、口径、频度或报送要求\n用户查询报表之间的校验、映射或主键挂接关系\n用户评估新产品、新业务或系统改造对监管报送的影响\n用户要求根据监管知识库解释概念、对比差异或提供原文依据',
            `memory_files` = '/AGENTS.md',
            `skill_dirs` = NULL,
            `tool_allowlist` = 'ls,read_file,glob,grep',
            `policy_config` = '{"write":"deny","execute":"deny","workspace_root":"/Users/zhoujingkun/Documents/GitHub/urgs/regulatory-knowledge-vault"}',
            `sort_order` = 100,
            `updated_at` = NOW()
        WHERE `agent_code` = 'regulatory-knowledge-agent';
    END IF;
END$$
DELIMITER ;

CALL ExecuteIdempotent_V104();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V104;
