package com.example.urgs_api.metadata.review.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.List;

@Data
@AllArgsConstructor
public class LineageReviewAuditResult {
    private List<LineageReviewAIVerdict> verdicts;
    private int aiCallCount;
    private String failureReason;

    public boolean isSuccess() {
        return failureReason == null || failureReason.isBlank();
    }

    public static LineageReviewAuditResult success(List<LineageReviewAIVerdict> verdicts, int aiCallCount) {
        return new LineageReviewAuditResult(verdicts, aiCallCount, null);
    }

    public static LineageReviewAuditResult failed(int aiCallCount, String failureReason) {
        return new LineageReviewAuditResult(List.of(), aiCallCount, failureReason);
    }
}
