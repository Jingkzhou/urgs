package com.example.urgs_api.metadata.review.dto;

import lombok.Data;

@Data
public class LineageReviewDecisionRequest {
    private String reviewStatus;
    private String reviewerNote;
    private String falsePositiveReason;
    private String confirmedProblemType;
    private String confirmedProblemDescription;
}
