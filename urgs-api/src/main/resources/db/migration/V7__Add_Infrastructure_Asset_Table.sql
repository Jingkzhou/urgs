-- Add table for Infrastructure Assets
CREATE TABLE `t_infrastructure_asset` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `hostname` varchar(100) NOT NULL COMMENT '主机名',
  `internal_ip` varchar(50) NOT NULL COMMENT '内网 IP 地址',
  `external_ip` varchar(50) DEFAULT NULL COMMENT '公网 IP 地址',
  `os_type` varchar(50) DEFAULT NULL COMMENT '操作系统类型',
  `os_version` varchar(100) DEFAULT NULL COMMENT '操作系统版本',
  `cpu` varchar(50) DEFAULT NULL COMMENT 'CPU 配置',
  `memory` varchar(50) DEFAULT NULL COMMENT '内存配置',
  `disk` varchar(100) DEFAULT NULL COMMENT '磁盘配置',
  `role` varchar(50) DEFAULT NULL COMMENT '服务器角色',
  `app_system_id` bigint(20) DEFAULT NULL COMMENT '关联应用系统ID',
  `env_id` bigint(20) DEFAULT NULL COMMENT '关联环境ID',
  `status` varchar(20) DEFAULT 'active' COMMENT '状态',
  `description` text COMMENT '备注信息',
  `created_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` timestamp NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='基础设施资产表';
