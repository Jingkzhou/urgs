package com.example.urgs_api.marketplace.dto;

import lombok.Data;

@Data
public class TaskSubmissionDTO {
    private String completionDescription;
    private String deliverables;
    private Integer actualHours;
    private String impactScope;
    private Boolean delayReported;
    private String delayReason;
}
