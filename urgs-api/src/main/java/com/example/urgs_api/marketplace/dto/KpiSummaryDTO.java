package com.example.urgs_api.marketplace.dto;

import lombok.Data;

@Data
public class KpiSummaryDTO {
    private String userId;
    private String userName;
    private Integer completedTaskCount;
    private Integer basePoints;
    private Integer finalPoints;
    private Double onTimeRate;
    private Double averageQualityScore;
    private Integer reworkCount;
    private Integer overdueCount;
    private Integer highPriorityTaskCount;
    private Integer activeTaskCount;
}
