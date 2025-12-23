-- Add rag_instruction column to t_ai_agent table
ALTER TABLE t_ai_agent ADD COLUMN rag_instruction TEXT COMMENT 'Custom RAG System Prompt Instructions';
