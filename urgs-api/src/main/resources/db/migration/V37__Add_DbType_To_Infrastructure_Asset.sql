-- Add db_type column to t_infrastructure_asset
ALTER TABLE t_infrastructure_asset ADD COLUMN db_type varchar(50) DEFAULT NULL COMMENT '数据库类型';
