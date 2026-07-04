package com.example.urgs_api.marketplace.dto;

import lombok.Data;

import java.util.List;

@Data
public class TeamKpiDTO {
    private Integer totalWorks;
    private Integer completedWorks;
    private Integer inProgressTasks;
    private Integer pausedTasks;
    private Integer overdueTasks;
    private Integer totalPointPool;
    private Integer settledPoints;
    private List<KpiSummaryDTO> rankings;
}
