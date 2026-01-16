-- 添加知识增强提示词配置字段
ALTER TABLE `t_ai_knowledge_base` ADD COLUMN `enrich_prompt` TEXT COMMENT '知识增强提示词模板' AFTER `embedding_model`;
