-- ============================================================
-- V83: 修复 V82 迁移未正确添加 favorite 列的问题
-- ============================================================

-- 1. 添加 favorite 列（若不存在）
SET @col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = (SELECT DATABASE())
      AND TABLE_NAME = 'online_document'
      AND COLUMN_NAME = 'favorite'
);
SET @sql = IF(@col_exists = 0,
    'ALTER TABLE online_document
     ADD COLUMN favorite TINYINT(1) NOT NULL DEFAULT 0
     COMMENT ''是否收藏（0=否，1=是）'' AFTER file_size',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 2. 迁移 is_favorite 数据到 favorite（若 is_favorite 存在）
SET @old_col_exists = (
    SELECT COUNT(*) FROM information_schema.COLUMNS
    WHERE TABLE_SCHEMA = (SELECT DATABASE())
      AND TABLE_NAME = 'online_document'
      AND COLUMN_NAME = 'is_favorite'
);
SET @sql = IF(@old_col_exists = 1,
    'UPDATE online_document SET favorite = is_favorite WHERE favorite = 0',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- 3. 删除旧列 is_favorite（使用单独的 ALTER TABLE，不与 UPDATE 混在一个 PREPARE 中）
SET @sql = IF(@old_col_exists = 1,
    'ALTER TABLE online_document DROP COLUMN is_favorite',
    'SELECT 1');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;
