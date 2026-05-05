package com.example.urgs_api.marketplace.dto;

import lombok.Data;

@Data
public class TaskReviewDTO {
    private String decision;
    private Integer qualityScore;
    private String reviewComment;
    private Integer bonusPoints;
    private Integer penaltyPoints;
    private String transferAssigneeId;
}
