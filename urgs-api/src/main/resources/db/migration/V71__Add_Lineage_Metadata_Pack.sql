DROP PROCEDURE IF EXISTS ExecuteIdempotent_V71;
DELIMITER $$
CREATE PROCEDURE ExecuteIdempotent_V71()
BEGIN
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION BEGIN END;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'physical_data_source_id'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `physical_data_source_id` BIGINT DEFAULT NULL COMMENT '物理模型数据源ID' AFTER `language`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_owner'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_owner` VARCHAR(255) DEFAULT NULL COMMENT '物理模型Schema/Owner' AFTER `physical_data_source_id`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_pack_path'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_pack_path` VARCHAR(1000) DEFAULT NULL COMMENT '血缘解析元数据包路径' AFTER `metadata_owner`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_pack_hash'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_pack_hash` VARCHAR(64) DEFAULT NULL COMMENT '血缘解析元数据包SHA-256' AFTER `metadata_pack_path`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_pack_status'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_pack_status` VARCHAR(32) DEFAULT NULL COMMENT '元数据包状态: DISABLED READY EMPTY FAILED' AFTER `metadata_pack_hash`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_table_count'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_table_count` INT DEFAULT 0 COMMENT '元数据包表数量' AFTER `metadata_pack_status`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_field_count'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_field_count` INT DEFAULT 0 COMMENT '元数据包字段数量' AFTER `metadata_table_count`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 't_lineage_analysis_record'
          AND COLUMN_NAME = 'metadata_generated_at'
    ) THEN
        ALTER TABLE `t_lineage_analysis_record`
            ADD COLUMN `metadata_generated_at` DATETIME DEFAULT NULL COMMENT '元数据包生成时间' AFTER `metadata_field_count`;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM information_schema.STATISTICS
        WHERE TABLE_SCHEMA = DATABASE()
          AND TABLE_NAME = 'model_field'
          AND INDEX_NAME = 'idx_model_field_table_id'
    ) THEN
        ALTER TABLE `model_field`
            ADD INDEX `idx_model_field_table_id` (`table_id`, `sort_order`);
    END IF;
END$$
DELIMITER ;
CALL ExecuteIdempotent_V71();
DROP PROCEDURE IF EXISTS ExecuteIdempotent_V71;
