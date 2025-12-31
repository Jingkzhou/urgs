package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_task")
public class Task {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String name;
    private String type;
    private String systemId;
    private String content; // JSON content

    private String cronExpression;
    private String dataDateRule;
    private Integer status; // 1: Enable, 0: Disable
    private LocalDateTime lastTriggerTime;
    private Integer priority;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
