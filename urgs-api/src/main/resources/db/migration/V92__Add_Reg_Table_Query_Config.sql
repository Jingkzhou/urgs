DROP PROCEDURE IF EXISTS ExecuteIdempotent_V92;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V92()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_table'
          AND COLUMN_NAME = 'query_table_type'
    ) THEN
        ALTER TABLE `reg_table`
            ADD COLUMN `query_table_type` VARCHAR(16) NOT NULL DEFAULT 'SUMMARY'
            COMMENT '查询表类型: SUMMARY 汇总表 DETAIL 明细表';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_table_query_config'
    ) THEN
        CREATE TABLE `reg_table_query_config` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `reg_table_id` BIGINT NOT NULL COMMENT '监管报表ID',
            `enabled` TINYINT NOT NULL DEFAULT 0 COMMENT '是否启用查询配置',
            `data_source_id` BIGINT DEFAULT NULL COMMENT '数据源ID',
            `model_table_id` VARCHAR(64) DEFAULT NULL COMMENT '主查询物理模型表ID',
            `date_field_id` VARCHAR(64) DEFAULT NULL COMMENT '日期字段ID',
            `org_code_field_id` VARCHAR(64) DEFAULT NULL COMMENT '机构编号字段ID',
            `org_name_field_id` VARCHAR(64) DEFAULT NULL COMMENT '机构名称字段ID',
            `default_return_field_ids` TEXT NULL COMMENT '默认返回字段ID列表JSON',
            `filter_field_ids` TEXT NULL COMMENT '允许筛选字段ID列表JSON',
            `sort_field_ids` TEXT NULL COMMENT '允许排序字段ID列表JSON',
            `mask_field_ids` TEXT NULL COMMENT '脱敏字段ID列表JSON',
            `detail_max_rows` INT NOT NULL DEFAULT 5 COMMENT '明细最大返回行数，最大5',
            `create_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            `update_time` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_reg_table_query_config_table` (`reg_table_id`),
            KEY `idx_reg_table_query_config_model_table` (`model_table_id`),
            KEY `idx_reg_table_query_config_source` (`data_source_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管明细表查询配置';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V92();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V92;
