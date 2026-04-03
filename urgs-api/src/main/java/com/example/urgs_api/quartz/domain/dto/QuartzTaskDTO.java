package net.lab1024.smartadmin.module.support.quartz.domain.dto;

import net.lab1024.smartadmin.module.support.quartz.constant.TaskStatusEnum;
import io.swagger.annotations.ApiModelProperty;
import lombok.Data;

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
/**
 * @RequirementName: 监管调度平台对接ESB微信公众号短信平台需求
 * @Developer: 周敬坤
 * @ModifiedDate: 2025-03-19
 * @ModificationDescription: JLB_W2025020608_监管调度平台对接ESB微信公众号短信平台需求。
 */
@Data
public class QuartzTaskDTO {

    @ApiModelProperty("id")
    private Long id;

    @ApiModelProperty("任务名称")
    @NotNull(message = "任务名称不能为空")
    private String taskName;

    @ApiModelProperty("任务Bean")
    private String taskBean;

    @ApiModelProperty("任务参数")
    private String taskParams;

    @ApiModelProperty("cron")
    @NotNull(message = "cron表达式不能为空")
    private String taskCron;

    @ApiModelProperty("任务状态:"+ TaskStatusEnum.INFO)
    private Integer taskStatus;

    @ApiModelProperty("任务备注")
    private String remark;

    @ApiModelProperty("依赖ID")
    private String dependId;

    @ApiModelProperty("执行文件")
    @NotNull(message = "执行文件不能为空")
    private String exePath;

    @ApiModelProperty("url")
    private String url;

    @ApiModelProperty("任务类型")
    @NotNull(message = "任务类型不能为空")
    private int taskType;

    @ApiModelProperty("轮询周期")
    private Long period;

    @ApiModelProperty("用户名")
    @NotNull(message = "用户名不能为空")
    private String username;

    @ApiModelProperty("密码")
    @NotNull(message = "密码不能为空")
    private String password;

    @ApiModelProperty("驱动")
    private String driver;

    @ApiModelProperty("系统")
    private String taskSystem;

    @ApiModelProperty("主题")
    private String theme;

    @ApiModelProperty("偏移量")
    private int offset;

    @ApiModelProperty("失败时发送")
    private String notificationFailed;

    @ApiModelProperty("成功时发送")
    private String notificationCompleted;
}
