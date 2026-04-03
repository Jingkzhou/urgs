package com.example.urgs_api.quartz.domain.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

@Data
public class QuartzMissedTaskVO {

    @ApiModelProperty("任务ID")
    private Long taskId;

    @ApiModelProperty("任务名称")
    private String taskName;

    @ApiModelProperty("系统")
    private String taskSystem;

    @ApiModelProperty("主题")
    private String theme;

    @ApiModelProperty("Cron表达式")
    private String taskCron;

    @ApiModelProperty("依赖ID")
    private String dependId;

    @ApiModelProperty("任务类型")
    private int taskType;

    @ApiModelProperty("数据日期")
    private String expectedDate;

    @ApiModelProperty("状态: 未下发")
    private String missedStatus;

    @ApiModelProperty("等待时长(分钟)")
    private Long waitingMinutes;

    @ApiModelProperty("上次成功数据日期")
    private String lastSuccessDate;

    @ApiModelProperty("上次成功结束时间")
    private String lastSuccessTime;
}
