ALTER TABLE `t_quartz_task`
    ADD COLUMN `datasource_id` BIGINT NULL COMMENT '数据源主键' AFTER `exe_path`;

ALTER TABLE `t_quartz_task`
    ADD INDEX `idx_quartz_task_datasource_id` (`datasource_id`);

ALTER TABLE `t_quartz_task`
    DROP COLUMN `url`,
    DROP COLUMN `username`,
    DROP COLUMN `password`,
    DROP COLUMN `driver`;
