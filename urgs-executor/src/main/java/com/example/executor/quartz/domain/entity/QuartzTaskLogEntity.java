package com.example.executor.quartz.domain.entity;

import lombok.Data;

import java.util.Date;

@Data
public class QuartzTaskLogEntity {

    private Long id;
    private Long taskId;
    private String taskName;
    private String taskParams;
    private Integer processStatus;
    private Long processDuration;
    private String processLog;
    private String ipAddress;
    private Date createTime;
    private Date updateTime;
}

