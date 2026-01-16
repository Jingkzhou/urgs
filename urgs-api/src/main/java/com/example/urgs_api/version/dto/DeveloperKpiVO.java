package com.example.urgs_api.version.dto;

import lombok.Data;

@Data
public class DeveloperKpiVO {
    private Long userId;
    private String name;
    private String email;
    private Integer totalCommits;
    private Integer totalReviews;
    private Double averageCodeScore; // 0-100
    private Integer activeDays;
    private Integer bugCount; // Potential future metric
}
