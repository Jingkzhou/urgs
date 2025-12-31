package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import java.time.LocalDateTime;

@Data
@TableName("sys_task_instance")
public class ExecutorTaskInstance {
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
    @com.baomidou.mybatisplus.annotation.TableField("system_id")
    private Long systemId;
    private String dataDate;
    private String status; // WAITING, RUNNING, SUCCESS, FAIL, FORCE_SUCCESS
    private Integer retryCount;
    private String logPath;
    @com.baomidou.mybatisplus.annotation.TableField("content_snapshot")
    private String contentSnapshot;

    public Long getSystemId() {
        return systemId;
    }

    public void setSystemId(Long systemId) {
        this.systemId = systemId;
    }

    public String getContentSnapshot() {
        return contentSnapshot;
    }

    public void setContentSnapshot(String contentSnapshot) {
        this.contentSnapshot = contentSnapshot;
    }

    private LocalDateTime startTime;
    private LocalDateTime endTime;

    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    @com.baomidou.mybatisplus.annotation.TableField("log_content")
    private String logContent;
}
