ALTER TABLE t_ai_agent ADD COLUMN dify_api_key VARCHAR(255) COMMENT 'Dify App API Key';
ALTER TABLE t_ai_agent ADD COLUMN dify_api_base VARCHAR(255) COMMENT 'Dify API Base URL';
ALTER TABLE ai_chat_session ADD COLUMN dify_conversation_id VARCHAR(255) COMMENT 'Dify Conversation ID';
