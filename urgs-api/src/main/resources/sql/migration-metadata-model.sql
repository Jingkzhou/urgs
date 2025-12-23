ALTER TABLE model_table
    MODIFY COLUMN `directory_id` VARCHAR(32) DEFAULT NULL COMMENT '所属目录ID';

ALTER TABLE model_table
    ADD COLUMN `data_source_id` BIGINT(20) DEFAULT NULL COMMENT '数据源ID' AFTER `directory_id`,
    ADD COLUMN `owner` VARCHAR(100) DEFAULT NULL COMMENT '所属用户/Schema' AFTER `data_source_id`;

CREATE INDEX idx_model_table_source_owner ON model_table (`data_source_id`, `owner`);
