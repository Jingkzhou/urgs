package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class TaskReviewHistoryDTO {
    private String id;
    private String taskId;
    private String taskTitle;
    private String taskStatus;
    private String workId;
    private String workTitle;
    private String requirementNumber;
    private String reviewType;
    private String decision;
    private String action;
    private String detail;
    private String reviewerId;
    private String reviewerName;
    private LocalDateTime reviewedAt;
}
