-- Migration: Add summary column to ai_chat_session
ALTER TABLE `ai_chat_session` ADD COLUMN `summary` longtext DEFAULT NULL COMMENT '前情提要(压缩上下文)';
