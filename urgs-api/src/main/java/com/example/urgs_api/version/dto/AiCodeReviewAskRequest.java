package com.example.urgs_api.version.dto;

import lombok.Data;

@Data
public class AiCodeReviewAskRequest {
    private String question;
    private String issueTitle;
    private String issueSeverity;
}
