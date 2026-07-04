package com.example.urgs_api.marketplace.dto;

import lombok.Data;

@Data
public class MarketplaceTodoDTO {
    private String type;
    private String title;
    private String description;
    private Integer count;
    private String targetTab;
    private String severity;
    private String targetTaskId;
    private String targetWorkId;
}
