-- ----------------------------
-- 工作市场权限点初始化脚本
-- 对应 manifest.ts 中的定义
-- ----------------------------

-- 1. 工作市场 (一级菜单)
INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) 
SELECT 'marketplace', '工作市场', 'menu', '/marketplace', NULL, 50, 1 
WHERE NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'marketplace');

-- ----------------------------
-- 自动授权给系统管理员角色 (假设角色ID为1)
-- ----------------------------
INSERT IGNORE INTO `sys_role_function` (`role_id`, `function_id`)
SELECT 1, `id` FROM `sys_function` WHERE `code` LIKE 'marketplace%';
