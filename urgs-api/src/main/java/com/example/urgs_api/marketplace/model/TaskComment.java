package com.example.urgs_api.marketplace.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_task_comment")
public class TaskComment {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;

    private String taskId;
    private String userId;
    private String content;
    private LocalDateTime createTime;
}
