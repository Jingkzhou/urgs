-- Add env_type column to t_infrastructure_asset
ALTER TABLE `t_infrastructure_asset` 
ADD COLUMN `env_type` varchar(50) DEFAULT NULL COMMENT '环境类型 (测试/生产/自定义)' 
AFTER `env_id`;
