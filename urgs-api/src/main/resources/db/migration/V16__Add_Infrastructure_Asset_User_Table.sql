-- V16__Add_Infrastructure_Asset_User_Table.sql
-- Create table for storing infrastructure asset users/credentials

CREATE TABLE IF NOT EXISTS `t_infrastructure_user` (
    `id` BIGINT NOT NULL AUTO_INCREMENT COMMENT 'ID',
    `username` VARCHAR(100) NOT NULL COMMENT '用户名',
    `password` VARCHAR(255) COMMENT '密码',
    `description` VARCHAR(500) COMMENT '说明',
    `asset_id` BIGINT NOT NULL COMMENT '关联资产ID',
    `created_at` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `updated_at` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    PRIMARY KEY (`id`),
    CONSTRAINT `fk_infra_user_asset` FOREIGN KEY (`asset_id`) REFERENCES `t_infrastructure_asset` (`id`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='基础设施资产用户表';

CREATE INDEX `idx_infra_user_asset_id` ON `t_infrastructure_user` (`asset_id`);
