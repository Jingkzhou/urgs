-- AI 智能体表
CREATE TABLE IF NOT EXISTS `t_ai_agent` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `name` VARCHAR(100) NOT NULL COMMENT '名称',
    `description` VARCHAR(1000) COMMENT '描述',
    `system_prompt` TEXT COMMENT '系统提示词',
    `status` TINYINT DEFAULT 1 COMMENT '状态 (1: 启用, 0: 禁用)',
    `knowledge_base` VARCHAR(100) COMMENT '关联知识库名称',
    `prompts` TEXT COMMENT '常用提示词 (JSON)',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 智能体配置表';

-- AI 知识库表
CREATE TABLE IF NOT EXISTS `t_ai_knowledge_base` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键',
    `name` VARCHAR(100) NOT NULL UNIQUE COMMENT '知识库名称',
    `description` VARCHAR(1000) COMMENT '描述',
    `collection_name` VARCHAR(100) COMMENT '向量集合名称',
    `embedding_model` VARCHAR(100) COMMENT 'Embedding 模型名称',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='AI 知识库配置表';
