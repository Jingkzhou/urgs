-- V39__Knowledge_Shared_Space.sql
-- 知识中心共享空间支持:
-- 1. knowledge_folder: 新增 scope 字段 (private/shared)
-- 2. knowledge_document: 新增 scope 字段 + source_doc_id (从共享复制时记录原始ID)

DROP PROCEDURE IF EXISTS ExecuteIdempotent_V39;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V39()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    -- ===== knowledge_folder 扩展 =====

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'knowledge_folder'
        AND COLUMN_NAME = 'scope'
    ) THEN
        ALTER TABLE `knowledge_folder`
            ADD COLUMN `scope` VARCHAR(20) DEFAULT 'private' COMMENT '空间类型: private(私人)/shared(共享)' AFTER `name`;
    END IF;

    -- ===== knowledge_document 扩展 =====

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'knowledge_document'
        AND COLUMN_NAME = 'scope'
    ) THEN
        ALTER TABLE `knowledge_document`
            ADD COLUMN `scope` VARCHAR(20) DEFAULT 'private' COMMENT '空间类型: private(私人)/shared(共享)' AFTER `title`;
    END IF;

    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 'knowledge_document'
        AND COLUMN_NAME = 'source_doc_id'
    ) THEN
        ALTER TABLE `knowledge_document`
            ADD COLUMN `source_doc_id` BIGINT NULL COMMENT '来源文档ID（从共享空间复制时记录原始ID）' AFTER `scope`;
    END IF;

END$$
DELIMITER ;
CALL ExecuteIdempotent_V39();
DROP PROCEDURE ExecuteIdempotent_V39;
