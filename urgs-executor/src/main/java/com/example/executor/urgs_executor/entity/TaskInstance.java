package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_task_instance")
public class TaskInstance {
    @TableId(type = IdType.AUTO)
    private Long id;

    public static final String STATUS_WAITING = "WAITING";
    public static final String STATUS_PENDING = "PENDING";
    public static final String STATUS_RUNNING = "RUNNING";
    public static final String STATUS_SUCCESS = "SUCCESS";
    public static final String STATUS_FAIL = "FAIL";
    public static final String STATUS_FORCE_SUCCESS = "FORCE_SUCCESS";

    private String taskId;
    private String taskType;
    private String dataDate;
    private String status; // WAITING, RUNNING, SUCCESS, FAIL, FORCE_SUCCESS
    private Integer retryCount;
    private String logPath;
    private String contentSnapshot;
    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    @com.baomidou.mybatisplus.annotation.TableField("log_content")
    private String logContent;
}
