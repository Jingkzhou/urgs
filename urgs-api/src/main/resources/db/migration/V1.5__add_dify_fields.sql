-- 使用存储过程实现幂等添加列，避免 Duplicate column name 错误
DROP PROCEDURE IF EXISTS AddColumnUnlessExists;
DELIMITER //
CREATE PROCEDURE AddColumnUnlessExists(
    IN tableName VARCHAR(64),
    IN columnName VARCHAR(64),
    IN columnDefinition VARCHAR(255)
)
BEGIN
    DECLARE col_count INT;
    SELECT COUNT(*) INTO col_count 
    FROM information_schema.columns 
    WHERE table_schema = SCHEMA()
      AND table_name = tableName 
      AND column_name = columnName;
      
    IF col_count = 0 THEN
        SET @s = CONCAT('ALTER TABLE ', tableName, ' ADD COLUMN ', columnName, ' ', columnDefinition);
        PREPARE stmt FROM @s;
        EXECUTE stmt;
        DEALLOCATE PREPARE stmt;
    END IF;
END //
DELIMITER ;

-- 处理 t_ai_agent 表
CALL AddColumnUnlessExists('t_ai_agent', 'dify_api_key', 'VARCHAR(255) COMMENT \'Dify App API Key\'');
CALL AddColumnUnlessExists('t_ai_agent', 'dify_api_base', 'VARCHAR(255) COMMENT \'Dify API Base URL\'');

-- 处理 ai_chat_session 表
CALL AddColumnUnlessExists('ai_chat_session', 'dify_conversation_id', 'VARCHAR(255) COMMENT \'Dify Conversation ID\'');

DROP PROCEDURE IF EXISTS AddColumnUnlessExists;
