-- ----------------------------
-- 知识中心权限点初始化脚本
-- 对应 manifest.ts 中的定义
-- ----------------------------

-- 1. 知识中心 (一级菜单)
INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) 
SELECT 'knowledge', '知识中心', 'menu', '/knowledge', NULL, 80, 1 
WHERE NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'knowledge');

-- 获取父节点ID
SET @parentId = (SELECT `id` FROM `sys_function` WHERE `code` = 'knowledge');

-- 2. 全部文档 (二级菜单)
INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) 
SELECT 'knowledge:view', '全部文档', 'menu', '/knowledge/all', @parentId, 10, 1 
WHERE NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'knowledge:view');

SET @docMenuId = (SELECT `id` FROM `sys_function` WHERE `code` = 'knowledge:view');

-- 2.1 文档操作按钮
INSERT IGNORE INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) VALUES
('knowledge:doc:create', '新建文档', 'button', '-', @docMenuId, 1, 1),
('knowledge:doc:edit', '编辑文档', 'button', '-', @docMenuId, 2, 1),
('knowledge:doc:delete', '删除文档', 'button', '-', @docMenuId, 3, 1);

-- 3. 文件夹管理 (二级菜单)
INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) 
SELECT 'knowledge:folder', '文件夹管理', 'menu', '/knowledge/folder', @parentId, 20, 1 
WHERE NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'knowledge:folder');

SET @folderMenuId = (SELECT `id` FROM `sys_function` WHERE `code` = 'knowledge:folder');

-- 3.1 文件夹操作按钮
INSERT IGNORE INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) VALUES
('knowledge:folder:create', '新建文件夹', 'button', '-', @folderMenuId, 1, 1),
('knowledge:folder:delete', '删除文件夹', 'button', '-', @folderMenuId, 2, 1);

-- 4. 标签管理 (二级菜单)
INSERT INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) 
SELECT 'knowledge:tag', '标签管理', 'menu', '/knowledge/tag', @parentId, 30, 1 
WHERE NOT EXISTS (SELECT 1 FROM `sys_function` WHERE `code` = 'knowledge:tag');

SET @tagMenuId = (SELECT `id` FROM `sys_function` WHERE `code` = 'knowledge:tag');

-- 4.1 标签操作按钮
INSERT IGNORE INTO `sys_function` (`code`, `name`, `type`, `path`, `parent_id`, `sort_order`, `enabled`) VALUES
('knowledge:tag:create', '新建标签', 'button', '-', @tagMenuId, 1, 1),
('knowledge:tag:delete', '删除标签', 'button', '-', @tagMenuId, 2, 1);

-- ----------------------------
-- 自动授权给系统管理员角色 (假设角色ID为1)
-- ----------------------------
INSERT IGNORE INTO `sys_role_function` (`role_id`, `function_id`)
SELECT 1, `id` FROM `sys_function` WHERE `code` LIKE 'knowledge%';
