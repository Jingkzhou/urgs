-- 4. Workflow Definition Table
DROP TABLE IF EXISTS `sys_workflow`;
CREATE TABLE `sys_workflow` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL COMMENT 'Workflow Name',
  `owner` varchar(50) DEFAULT NULL COMMENT 'Owner',
  `description` varchar(500) DEFAULT NULL COMMENT 'Description',
  `content` longtext DEFAULT NULL COMMENT 'Graph JSON',
  `create_time` datetime DEFAULT CURRENT_TIMESTAMP,
  `update_time` datetime DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Workflow Definitions';
