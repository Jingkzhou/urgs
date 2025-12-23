-- AI API 配置表
CREATE TABLE IF NOT EXISTS `sys_ai_api` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `name` VARCHAR(100) NOT NULL COMMENT '配置名称',
    `provider` VARCHAR(50) NOT NULL COMMENT 'AI 服务提供商 (openai, azure, anthropic, gemini, deepseek, qwen, glm 等)',
    `model` VARCHAR(100) COMMENT '模型名称',
    `endpoint` VARCHAR(500) NOT NULL COMMENT 'API 端点 URL',
    `api_key` VARCHAR(500) NOT NULL COMMENT 'API 密钥',
    `api_key_backup` VARCHAR(500) COMMENT '备用密钥',
    `max_tokens` INT DEFAULT 4096 COMMENT '最大 Token 数',
    `temperature` DOUBLE DEFAULT 0.7 COMMENT '温度参数',
    `is_default` TINYINT DEFAULT 0 COMMENT '是否默认配置 (1: 是, 0: 否)',
    `status` TINYINT DEFAULT 1 COMMENT '状态 (1: 启用, 0: 禁用)',
    `remark` VARCHAR(500) COMMENT '备注',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    INDEX `idx_provider` (`provider`),
    INDEX `idx_status` (`status`),
    INDEX `idx_is_default` (`is_default`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI API 配置表';

-- 插入示例数据
INSERT INTO `sys_ai_api` (`name`, `provider`, `model`, `endpoint`, `api_key`, `max_tokens`, `temperature`, `is_default`, `status`, `remark`) VALUES
('OpenAI GPT-4', 'openai', 'gpt-4', 'https://api.openai.com/v1', 'sk-xxxx', 4096, 0.7, 0, 1, 'OpenAI 官方 API'),
('DeepSeek Chat', 'deepseek', 'deepseek-chat', 'https://api.deepseek.com/v1', 'sk-xxxx', 4096, 0.7, 1, 1, 'DeepSeek 官方 API');
