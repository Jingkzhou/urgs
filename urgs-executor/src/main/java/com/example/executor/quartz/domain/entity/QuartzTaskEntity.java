package com.example.executor.quartz.domain.entity;

import lombok.Data;

@Data
public class QuartzTaskEntity {

    private Long id;
    private String taskName;
    private String taskBean;
    private String taskParams;
    private String taskCron;
    private Integer taskStatus;
    private String remark;
    private String dependId;
    private String dataDependId;
    private String controlDependId;
    private String exePath;
    private Integer taskType;
    private Long period;
    private Long datasourceId;
    private String datasourceName;
    private String taskSystem;
    private String theme;
    private Integer offset;
    private String dataDate;
    private String jobKey;
    private String notificationCompleted;
    private String notificationFailed;
}
