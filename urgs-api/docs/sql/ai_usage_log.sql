-- AI Token 使用统计

-- 扩展 AI 配置表，添加统计字段
ALTER TABLE sys_ai_api ADD COLUMN IF NOT EXISTS total_tokens BIGINT DEFAULT 0 COMMENT '累计消耗 Token';
ALTER TABLE sys_ai_api ADD COLUMN IF NOT EXISTS total_requests INT DEFAULT 0 COMMENT '累计请求次数';

-- AI 使用记录表
CREATE TABLE IF NOT EXISTS `ai_usage_log` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `config_id` BIGINT NOT NULL COMMENT '关联的 AI 配置 ID',
    `model` VARCHAR(100) COMMENT '模型名称',
    `prompt_tokens` INT DEFAULT 0 COMMENT '输入 Token 数',
    `completion_tokens` INT DEFAULT 0 COMMENT '输出 Token 数',
    `total_tokens` INT DEFAULT 0 COMMENT '总 Token 数',
    `request_type` VARCHAR(50) COMMENT '请求类型 (report/chat/test)',
    `success` TINYINT(1) DEFAULT 1 COMMENT '是否成功',
    `error_message` VARCHAR(500) COMMENT '错误信息',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    INDEX `idx_config_id` (`config_id`),
    INDEX `idx_create_time` (`create_time`),
    INDEX `idx_model` (`model`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI Token 使用记录';
