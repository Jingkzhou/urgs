package com.example.urgs_api.quartz.domain.dto;

import lombok.Data;

@Data
public class QuartzTaskStatusStatsVO {
    private Long totalInstances;
    private Long waitingInstances;
    private Long runningInstances;
    private Long successInstances;
    private Long failedInstances;
}
