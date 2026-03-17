package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_task_application")
public class TaskApplication {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String taskId;
    private String applicantId;
    private String message;
    private String status;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}
