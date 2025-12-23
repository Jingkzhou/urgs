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

CREATE TABLE IF NOT EXISTS `sys_datasource_config` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT COMMENT 'Primary Key',
  `name` varchar(100) NOT NULL COMMENT 'Connection Name',
  `meta_id` bigint(20) NOT NULL COMMENT 'Reference to sys_datasource_meta.id',
  `connection_params` json NOT NULL COMMENT 'Connection Parameters (JSON)',
  `status` int(11) DEFAULT 1 COMMENT 'Status (1: Valid, 0: Invalid)',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP COMMENT 'Creation Time',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Dynamic Data Source Configuration';
