package com.example.urgs_api.version.dto;

import lombok.Data;

import java.time.LocalDateTime;

@Data
public class AiCodeReviewAskResponse {
    private Long reviewId;
    private String answer;
    private LocalDateTime generatedAt;

    public AiCodeReviewAskResponse(Long reviewId, String answer) {
        this.reviewId = reviewId;
        this.answer = answer;
        this.generatedAt = LocalDateTime.now();
    }
}
