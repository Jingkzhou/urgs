-- ----------------------------
-- 补全系统缺失的权限表
-- ----------------------------

CREATE TABLE IF NOT EXISTS `sys_function` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID',
    `code` VARCHAR(100) NOT NULL COMMENT '权限编码',
    `name` VARCHAR(100) NOT NULL COMMENT '权限名称',
    `type` VARCHAR(50) NOT NULL COMMENT '类型: menu, button',
    `path` VARCHAR(255) COMMENT '前端路由路径',
    `parent_id` BIGINT COMMENT '父ID',
    `sort_order` INT DEFAULT 0 COMMENT '排序',
    `enabled` INT DEFAULT 1 COMMENT '是否启用',
    `create_time` DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    `update_time` DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    UNIQUE KEY `uk_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='系统权限功能表';

CREATE TABLE IF NOT EXISTS `sys_role_function` (
    `id` BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT 'ID',
    `role_id` BIGINT NOT NULL COMMENT '角色ID',
    `function_id` BIGINT NOT NULL COMMENT '功能ID',
    UNIQUE KEY `uk_role_func` (`role_id`, `function_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='角色权限关联表';
