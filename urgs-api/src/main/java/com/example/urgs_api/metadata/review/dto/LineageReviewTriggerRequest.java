package com.example.urgs_api.metadata.review.dto;

import lombok.Data;

@Data
public class LineageReviewTriggerRequest {
    private String analysisRecordId;
    private Boolean forceRerun;
}
