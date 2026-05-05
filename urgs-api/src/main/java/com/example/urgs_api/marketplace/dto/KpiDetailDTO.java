package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class KpiDetailDTO {
    private String taskId;
    private String taskTitle;
    private String workId;
    private String workTitle;
    private String requirementNumber;
    private String assigneeId;
    private String assigneeName;
    private Integer basePoints;
    private Integer finalPoints;
    private Integer qualityScore;
    private Integer reworkCount;
    private Boolean onTime;
    private Integer actualHours;
    private String reviewerId;
    private String reviewComment;
    private LocalDateTime reviewedAt;
}
