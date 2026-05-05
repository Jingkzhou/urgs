package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TaskApplicationDTO {
    private String id;
    private String taskId;
    private String taskTitle;
    private String workId;
    private String workTitle;
    private Integer taskPoints;
    private String applicantId;
    private String applicantName;
    private String message;
    private String solution;
    private LocalDateTime expectedCompletionTime;
    private String status;
    private String reviewComment;
    private String reviewedBy;
    private LocalDateTime reviewedAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private Integer completedTaskCount;
    private Integer finalPoints;
    private Double onTimeRate;
    private Double averageQualityScore;
    private Integer currentLoad;
}
