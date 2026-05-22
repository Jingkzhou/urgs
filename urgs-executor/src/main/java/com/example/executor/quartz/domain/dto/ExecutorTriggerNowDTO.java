package com.example.executor.quartz.domain.dto;

import lombok.Data;

@Data
public class ExecutorTriggerNowDTO {
    private Long planId;
    private String dataDate;
    private String triggerType;
}
