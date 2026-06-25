package com.example.urgs_api.quartz.domain.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.util.Date;
import java.util.List;

@Data
public class QuartzDependencyImpactItemVO {

    private Long taskId;

    private String taskName;

    private String taskSystem;

    private String theme;

    private Long statusId;

    private String dataDate;

    private Integer status;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date beginTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date updateTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date endTime;

    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date createTime;

    private String msg;

    private Integer level;

    private List<String> dependencyTypes;

    private Boolean missingTask;

    private Boolean impacted;

    private Boolean hasImpactedDescendant;

    private Integer directChildCount;

    private Integer descendantCount;
}
