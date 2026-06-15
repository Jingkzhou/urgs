-- ============================================================
-- V82: 为 online_document 表添加 favorite 和 space_type 字段
--
-- ⚠️ 重要：此脚本不使用 DECLARE CONTINUE HANDLER 吞掉异常，
--    确保任何 SQL 错误都会传播到 Flyway，触发告警而不是静默成功。
-- ============================================================

-- 1. 添加 favorite 字段（与 MyBatis-Plus 驼峰映射保持一致）
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'online_document'
      AND COLUMN_NAME = 'favorite'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE online_document ADD COLUMN favorite TINYINT(1) NOT NULL DEFAULT 0 COMMENT ''是否收藏（0=否，1=是）'' AFTER file_size',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 兼容历史：若旧版本脚本遗留了 is_favorite 列，迁移数据后删除
SET @old_col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'online_document'
      AND COLUMN_NAME = 'is_favorite'
);
SET @sql = IF(@old_col_exists = 1,
    'UPDATE online_document SET favorite = is_favorite WHERE favorite = 0; ALTER TABLE online_document DROP COLUMN is_favorite',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 添加 space_type 字段（personal=个人空间，shared=共享空间）
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'online_document'
      AND COLUMN_NAME = 'space_type'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE online_document ADD COLUMN space_type VARCHAR(50) DEFAULT NULL COMMENT ''空间类型（personal=个人空间，shared=共享空间）'' AFTER favorite',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 4. 为历史文档填充默认空间类型
UPDATE online_document SET space_type = 'personal' WHERE space_type IS NULL;

-- 5. 添加索引优化查询
SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'online_document'
      AND INDEX_NAME = 'idx_owner_favorite'
);
SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE online_document ADD INDEX idx_owner_favorite (user_id, favorite, update_time)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @idx_exists = (
    SELECT COUNT(*) FROM information_schema.STATISTICS
    WHERE TABLE_SCHEMA = DATABASE()
      AND TABLE_NAME = 'online_document'
      AND INDEX_NAME = 'idx_owner_space'
);
SET @sql = IF(@idx_exists = 0,
    'ALTER TABLE online_document ADD INDEX idx_owner_space (user_id, space_type, update_time)',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
