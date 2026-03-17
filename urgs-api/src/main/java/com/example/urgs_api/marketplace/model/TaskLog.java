package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_task_log")
public class TaskLog {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String taskId;
    private String operatorId;
    private String action;
    private String detail;
    private LocalDateTime createTime;
}
