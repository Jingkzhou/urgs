package com.example.urgs_api.task.vo;

import lombok.Data;

@Data
public class UpstreamDependencyVO {
    private String taskId;
    private String taskName;
    private String status;
    private Long instanceId;
    private String startTime;
    private String endTime;
    private Integer level;
}
