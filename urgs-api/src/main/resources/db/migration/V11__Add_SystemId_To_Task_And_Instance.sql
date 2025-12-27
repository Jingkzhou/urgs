-- Add system_id to sys_task and sys_task_instance
ALTER TABLE sys_task ADD COLUMN system_id BIGINT COMMENT '关联系统ID';
ALTER TABLE sys_task_instance ADD COLUMN system_id BIGINT COMMENT '关联系统ID';
