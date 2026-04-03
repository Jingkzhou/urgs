package net.lab1024.smartadmin.module.support.quartz.domain.dto;

import io.swagger.annotations.ApiModelProperty;
import lombok.Data;
import net.lab1024.smartadmin.module.support.quartz.constant.TaskStatusEnum;

import javax.validation.constraints.NotNull;

/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/13 0013 下午 15:42
 * @since JDK1.8
 */
@Data
public class QuartzTaskStatusVO {
    @ApiModelProperty("statusID")
    private Long id;

    @ApiModelProperty("任务ID")
    private Long planId;

    @ApiModelProperty("任务名称")
    private String taskName;

    @ApiModelProperty("数据日期")
    private String dataDate;

    @ApiModelProperty("依赖任务ID")
    private String dependId;

    @ApiModelProperty("任务类型")
    private String taskType;

    @ApiModelProperty("cron")
    private String taskCron;

    @ApiModelProperty("执行文件")
    private String exePath;

    @ApiModelProperty("url")
    private String url;

    @ApiModelProperty("轮询周期")
    private String period;

    @ApiModelProperty("用户名")
    private String username;

    @ApiModelProperty("密码")
    private String password;

    @ApiModelProperty("驱动")
    private String driver;

    @ApiModelProperty("执行状态")
    private String status;

    @ApiModelProperty("开始时间")
    private String beginTime;

    @ApiModelProperty("结束时间")
    private String endTime;

    @ApiModelProperty("更新时间")
    private String updateTime;

    @ApiModelProperty("主题")
    private String theme;

    @ApiModelProperty("系统")
    private String taskSystem;

    @ApiModelProperty("备注")
    private String remark;

    @ApiModelProperty("错误描述")
    private String msg;

    @ApiModelProperty("jobKey")
    private String jobKey;

    @ApiModelProperty("创建时间")
    private String createTime;

    @ApiModelProperty("_disabled")
    private boolean _disabled;
}
