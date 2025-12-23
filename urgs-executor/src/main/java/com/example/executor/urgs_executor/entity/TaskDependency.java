package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

@Data
@TableName("sys_task_dependency")
public class TaskDependency {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String taskId; // Downstream Task
    private String preTaskId; // Upstream Task
}
