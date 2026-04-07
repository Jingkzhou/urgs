package com.example.urgs_api.quartz.domain.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

import java.util.Date;

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
/**
 * @RequirementName: 监管调度平台对接ESB微信公众号短信平台需求
 * @Developer: 周敬坤
 * @ModifiedDate: 2025-03-19
 * @ModificationDescription: JLB_W2025020608_监管调度平台对接ESB微信公众号短信平台需求。
 */
@Data
public class QuartzTaskVO {

    @ApiModelProperty("id")
    private Long id;

    @ApiModelProperty("任务名称")
    private String taskName;

    @ApiModelProperty("任务Bean")
    private String taskBean;

    @ApiModelProperty("任务参数")
    private String taskParams;

    @ApiModelProperty("cron")
    private String taskCron;

    @ApiModelProperty("任务状态")
    private Integer taskStatus;

    @ApiModelProperty("任务备注")
    private String remark;

    @ApiModelProperty("任务类型")
    private Integer taskType;

    @ApiModelProperty("执行文件")
    private String exePath;

    @ApiModelProperty("连接串或主机")
    private String url;

    @ApiModelProperty("依赖任务ID")
    private String dependId;

    @ApiModelProperty("轮询间隔")
    private Long period;

    @ApiModelProperty("系统")
    private String taskSystem;

    @ApiModelProperty("主题")
    private String theme;

    @ApiModelProperty("偏移量")
    private Integer offset;

    @ApiModelProperty("用户名")
    private String username;

    @ApiModelProperty("密码")
    private String password;

    @ApiModelProperty("驱动")
    private String driver;

    @ApiModelProperty("更新时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date updateTime;

    @ApiModelProperty("创建时间")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss", timezone = "Asia/Shanghai")
    private Date createTime;

    @ApiModelProperty("数据日期")
    private String dataDate;

    @ApiModelProperty("作业Key")
    private String jobKey;

    @ApiModelProperty("失败时发送")
    private String notificationFailed;
    @ApiModelProperty("成功时发送")
    private String notificationCompleted;

}
