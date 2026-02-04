ALTER TABLE t_ai_knowledge_base 
ADD COLUMN external_url VARCHAR(255) DEFAULT NULL COMMENT 'Dify API Endpoint',
ADD COLUMN external_api_key VARCHAR(255) DEFAULT NULL COMMENT 'Dify API Key';
