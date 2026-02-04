-- 添加 Dify 对接相关字段
ALTER TABLE `t_ai_knowledge_base` ADD COLUMN `provider` VARCHAR(50) DEFAULT 'LOCAL' COMMENT '知识库提供方: LOCAL, DIFY' AFTER `enrich_prompt`;
ALTER TABLE `t_ai_knowledge_base` ADD COLUMN `external_id` VARCHAR(100) COMMENT '外部系统标识 (如 Dify Dataset ID)' AFTER `provider`;
