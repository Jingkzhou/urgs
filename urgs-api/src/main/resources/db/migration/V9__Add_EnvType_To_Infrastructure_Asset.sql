-- Add env_type column to t_infrastructure_asset
DROP PROCEDURE IF EXISTS upgrade_v9_infra_env_type;

DELIMITER $$
CREATE PROCEDURE upgrade_v9_infra_env_type()
BEGIN
    IF NOT EXISTS (
        SELECT * FROM information_schema.COLUMNS
        WHERE TABLE_SCHEMA = DATABASE()
        AND TABLE_NAME = 't_infrastructure_asset'
        AND COLUMN_NAME = 'env_type'
    ) THEN
        ALTER TABLE `t_infrastructure_asset` 
        ADD COLUMN `env_type` varchar(50) DEFAULT NULL COMMENT '环境类型 (测试/生产/自定义)' 
        AFTER `env_id`;
    END IF;
END $$
DELIMITER ;

CALL upgrade_v9_infra_env_type();
DROP PROCEDURE IF EXISTS upgrade_v9_infra_env_type;
