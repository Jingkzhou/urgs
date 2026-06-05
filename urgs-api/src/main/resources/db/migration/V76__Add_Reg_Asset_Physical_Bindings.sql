DROP PROCEDURE IF EXISTS ExecuteIdempotent_V76;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V76()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_table_model_table_rel'
    ) THEN
        CREATE TABLE `reg_table_model_table_rel` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `reg_table_id` BIGINT NOT NULL COMMENT '监管报表ID',
            `model_table_id` VARCHAR(32) NOT NULL COMMENT '物理模型表ID',
            `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_reg_table_model_table` (`reg_table_id`, `model_table_id`),
            KEY `idx_reg_table_rel_table` (`reg_table_id`),
            KEY `idx_reg_table_rel_model` (`model_table_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管报表与物理表绑定关系';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.TABLES
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'reg_element_model_field_rel'
    ) THEN
        CREATE TABLE `reg_element_model_field_rel` (
            `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键ID',
            `reg_element_id` BIGINT NOT NULL COMMENT '监管字段/指标ID',
            `model_table_id` VARCHAR(32) NOT NULL COMMENT '物理模型表ID',
            `model_field_id` VARCHAR(32) NOT NULL COMMENT '物理模型字段ID',
            `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
            PRIMARY KEY (`id`),
            UNIQUE KEY `uk_reg_element_model_field` (`reg_element_id`, `model_field_id`),
            KEY `idx_reg_element_rel_element` (`reg_element_id`),
            KEY `idx_reg_element_rel_table` (`model_table_id`),
            KEY `idx_reg_element_rel_field` (`model_field_id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='监管字段指标与物理字段绑定关系';
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V76();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V76;
