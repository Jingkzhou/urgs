ALTER TABLE `t_quartz_task`
    MODIFY COLUMN `exe_path` TEXT
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci
    NULL
    COMMENT '执行路径或脚本';
