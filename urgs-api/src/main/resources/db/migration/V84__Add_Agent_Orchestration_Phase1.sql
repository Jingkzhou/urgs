DROP PROCEDURE IF EXISTS ExecuteIdempotent_V84;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V84()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'agent_code'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `agent_code` VARCHAR(64) DEFAULT NULL COMMENT 'Agent唯一编码' AFTER `id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'agent_type'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `agent_type` VARCHAR(32) DEFAULT 'SPECIALIST' COMMENT 'Agent类型: ROUTER SPECIALIST SUPERVISOR GENERAL' AFTER `name`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'capability_tags'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `capability_tags` TEXT NULL COMMENT '能力标签，支持JSON数组或分隔文本' AFTER `agent_app_tools`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'routing_examples'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `routing_examples` TEXT NULL COMMENT '路由示例，供Router Agent判断使用' AFTER `capability_tags`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'memory_files'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `memory_files` TEXT NULL COMMENT 'DeepAgents memory文件列表' AFTER `routing_examples`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'skill_dirs'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `skill_dirs` TEXT NULL COMMENT 'DeepAgents skills目录列表' AFTER `memory_files`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'tool_allowlist'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `tool_allowlist` TEXT NULL COMMENT '允许调用的工具白名单' AFTER `skill_dirs`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'policy_config'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `policy_config` TEXT NULL COMMENT 'Agent策略配置JSON' AFTER `tool_allowlist`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'model_config'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `model_config` TEXT NULL COMMENT 'Agent模型配置JSON' AFTER `policy_config`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND COLUMN_NAME = 'sort_order'
    ) THEN
        ALTER TABLE `t_ai_agent`
            ADD COLUMN `sort_order` INT DEFAULT 0 COMMENT '排序号' AFTER `model_config`;
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND INDEX_NAME = 'idx_t_ai_agent_agent_code'
    ) THEN
        ALTER TABLE `t_ai_agent` ADD INDEX `idx_t_ai_agent_agent_code` (`agent_code`);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 't_ai_agent' AND INDEX_NAME = 'idx_t_ai_agent_status_sort'
    ) THEN
        ALTER TABLE `t_ai_agent` ADD INDEX `idx_t_ai_agent_status_sort` (`status`, `sort_order`);
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_run'
    ) THEN
        CREATE TABLE `ai_agent_run` (
            `id` VARCHAR(64) NOT NULL COMMENT '运行ID',
            `session_id` VARCHAR(64) DEFAULT NULL COMMENT '会话ID',
            `user_id` VARCHAR(64) DEFAULT NULL COMMENT '用户ID',
            `agent_id` BIGINT DEFAULT NULL COMMENT 'Agent ID',
            `agent_code` VARCHAR(64) DEFAULT NULL COMMENT 'Agent编码',
            `agent_name` VARCHAR(128) DEFAULT NULL COMMENT 'Agent名称',
            `status` VARCHAR(32) DEFAULT 'RUNNING' COMMENT '运行状态',
            `user_prompt` TEXT NULL COMMENT '用户输入',
            `router_intent` VARCHAR(128) DEFAULT NULL COMMENT '路由任务类型',
            `router_confidence` DOUBLE DEFAULT NULL COMMENT '路由置信度',
            `start_time` DATETIME DEFAULT NULL COMMENT '开始时间',
            `end_time` DATETIME DEFAULT NULL COMMENT '结束时间',
            `error_message` TEXT NULL COMMENT '错误信息',
            PRIMARY KEY (`id`),
            KEY `idx_ai_agent_run_session` (`session_id`),
            KEY `idx_ai_agent_run_agent` (`agent_id`),
            KEY `idx_ai_agent_run_status_time` (`status`, `start_time`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Agent运行记录';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_run_event'
    ) THEN
        CREATE TABLE `ai_agent_run_event` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '事件ID',
            `run_id` VARCHAR(64) NOT NULL COMMENT '运行ID',
            `session_id` VARCHAR(64) DEFAULT NULL COMMENT '会话ID',
            `agent_id` BIGINT DEFAULT NULL COMMENT 'Agent ID',
            `agent_code` VARCHAR(64) DEFAULT NULL COMMENT 'Agent编码',
            `event_type` VARCHAR(64) NOT NULL COMMENT '事件类型',
            `title` VARCHAR(255) DEFAULT NULL COMMENT '事件标题',
            `content` TEXT NULL COMMENT '事件内容',
            `payload` LONGTEXT NULL COMMENT '事件载荷JSON',
            `status` VARCHAR(32) DEFAULT NULL COMMENT '事件状态',
            `create_time` DATETIME DEFAULT NULL COMMENT '创建时间',
            PRIMARY KEY (`id`),
            KEY `idx_ai_agent_run_event_run` (`run_id`, `id`),
            KEY `idx_ai_agent_run_event_session` (`session_id`),
            KEY `idx_ai_agent_run_event_type` (`event_type`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Agent运行事件';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'ai_agent_tool_call'
    ) THEN
        CREATE TABLE `ai_agent_tool_call` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '工具调用ID',
            `run_id` VARCHAR(64) NOT NULL COMMENT '运行ID',
            `session_id` VARCHAR(64) DEFAULT NULL COMMENT '会话ID',
            `agent_id` BIGINT DEFAULT NULL COMMENT 'Agent ID',
            `agent_code` VARCHAR(64) DEFAULT NULL COMMENT 'Agent编码',
            `tool_name` VARCHAR(128) DEFAULT NULL COMMENT '工具名称',
            `tool_call_id` VARCHAR(128) DEFAULT NULL COMMENT '上游工具调用ID',
            `input_summary` TEXT NULL COMMENT '输入摘要',
            `output_summary` TEXT NULL COMMENT '输出摘要',
            `status` VARCHAR(32) DEFAULT NULL COMMENT '调用状态',
            `started_at` DATETIME DEFAULT NULL COMMENT '开始时间',
            `finished_at` DATETIME DEFAULT NULL COMMENT '结束时间',
            `error_message` TEXT NULL COMMENT '错误信息',
            PRIMARY KEY (`id`),
            KEY `idx_ai_agent_tool_call_run` (`run_id`, `id`),
            KEY `idx_ai_agent_tool_call_tool` (`tool_name`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Agent工具调用记录';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V84();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V84;
