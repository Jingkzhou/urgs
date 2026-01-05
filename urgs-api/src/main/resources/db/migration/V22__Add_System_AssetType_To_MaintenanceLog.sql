-- Add system_code and asset_type to maintenance_record
ALTER TABLE `maintenance_record` ADD COLUMN `system_code` VARCHAR(50) COMMENT '所属系统';
ALTER TABLE `maintenance_record` ADD COLUMN `asset_type` VARCHAR(20) COMMENT '资产类型(REG_ASSET/CODE_VAL)';
