package com.example.urgs_api.metadata.review.dto;

import lombok.Data;

import java.math.BigDecimal;
import java.util.List;

@Data
public class LineageReviewAIVerdict {
    private String issueType;
    private String targetTable;
    private String targetColumn;
    private String severity;
    private BigDecimal confidence;
    private String verdict;
    private String reason;
    private List<String> suggestedSources;
    private List<String> evidenceRefs;
}
