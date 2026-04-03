CREATE TABLE IF NOT EXISTS t_quartz_task_log (
  id BIGINT AUTO_INCREMENT PRIMARY KEY COMMENT '主键ID',
  task_id BIGINT NOT NULL COMMENT '任务ID',
  task_name VARCHAR(200) DEFAULT NULL COMMENT '任务名称',
  task_params VARCHAR(1000) DEFAULT NULL COMMENT '任务参数',
  process_status TINYINT DEFAULT NULL COMMENT '处理状态：0成功，1失败',
  process_duration BIGINT DEFAULT NULL COMMENT '处理耗时ms',
  process_log LONGTEXT COMMENT '处理日志',
  ip_address VARCHAR(64) DEFAULT NULL COMMENT '执行主机IP',
  create_time DATETIME DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
  update_time DATETIME DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
  KEY idx_task_id_create_time (task_id, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='Quartz任务执行日志表';
