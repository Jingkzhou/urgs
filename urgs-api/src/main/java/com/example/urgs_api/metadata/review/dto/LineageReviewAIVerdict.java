package com.example.urgs_api.metadata.review.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class LineageReviewAIVerdict {
    private String statementUid;
    private String issueType;
    private String targetTable;
    private String targetColumn;
    private String severity;
    private BigDecimal confidence;
    private String verdict;
    private String summary;
    private String currentState;
    private String expectedState;
    private String reason;
    private String expectedRelationType;
    private String disposition;
    private String recommendation;
    private List<String> suggestedSources;
    private List<String> evidenceRefs;
}
