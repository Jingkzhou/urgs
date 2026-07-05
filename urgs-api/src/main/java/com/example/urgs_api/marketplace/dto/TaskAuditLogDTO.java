package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TaskAuditLogDTO {
    private String id;
    private String taskId;
    private String operatorId;
    private String operatorName;
    private String action;
    private String detail;
    private LocalDateTime createTime;
}
