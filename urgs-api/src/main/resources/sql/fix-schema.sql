-- Add meta_id column if it doesn't exist
SET @dbname = DATABASE();
SET @tablename = "sys_datasource_config";
SET @columnname = "meta_id";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE sys_datasource_config ADD COLUMN meta_id bigint(20) NOT NULL COMMENT 'Reference to sys_datasource_meta.id';"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Add connection_params column if it doesn't exist
SET @columnname = "connection_params";
SET @preparedStatement = (SELECT IF(
  (
    SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
    WHERE
      (table_name = @tablename)
      AND (table_schema = @dbname)
      AND (column_name = @columnname)
  ) > 0,
  "SELECT 1",
  "ALTER TABLE sys_datasource_config ADD COLUMN connection_params json NOT NULL COMMENT 'Connection Parameters (JSON)';"
));
PREPARE alterIfNotExists FROM @preparedStatement;
EXECUTE alterIfNotExists;
DEALLOCATE PREPARE alterIfNotExists;

-- Create sys_datasource_meta table if not exists
CREATE TABLE IF NOT EXISTS `sys_datasource_meta` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `code` varchar(50) NOT NULL COMMENT 'Data Source Code (e.g. mysql)',
  `name` varchar(100) NOT NULL COMMENT 'Display Name',
  `category` varchar(50) NOT NULL COMMENT 'Category (RDBMS, NoSQL, etc.)',
  `form_schema` json NOT NULL COMMENT 'Form Schema Definition',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation Time',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Data Source Metadata';
