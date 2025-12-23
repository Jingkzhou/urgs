package com.example.urgs_api.task.dto;

import lombok.Data;
import java.math.BigDecimal;

@Data
public class TaskStatsVO {
    private String systemId;
    private String systemName;
    private Integer totalTasks;
    private Integer totalCompleted;
    private Integer totalInProgress;
    private Integer totalNotStarted;
    private Integer totalFailed;
    private BigDecimal avgProgressPercentage;
}
