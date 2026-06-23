package com.example.urgs_api.quartz.domain.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import io.swagger.annotations.ApiModelProperty;
import com.example.urgs_api.quartz.support.domain.BaseEntity;
import lombok.Data;


/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/13 0013 下午 13:45
 * @since JDK1.8
 */
@Data
@TableName("t_quartz_task")
public class QuartzTaskEntity extends BaseEntity {
    @TableId(type = IdType.AUTO)
    private Long id;

    /**
     * 任务名称参数
     */
    private String taskName;
    /**
     * 任务类
     */
    private String taskBean;

    /**
     * 任务参数
     */
    private String taskParams;

    /**
     * cron
     */
    private String taskCron;

    /**
     * 任务状态
     */
    private Integer taskStatus;

    /**
     * 备注
     */
    private String remark;

    /**
     * 依赖id
     */
    private String dependId;

    /**
     * 数据依赖ID
     */
    @TableField(exist = false)
    private String dataDependId;

    /**
     * 控制依赖ID
     */
    @TableField(exist = false)
    private String controlDependId;

    /**
     * shell绝对路径proc用户名称
     */
    private String exePath;
    /**
     *任务类型1shell2proc
     */
    private Integer taskType;
    /**
     * 任务自动轮询时间  毫秒
     */
    private Long period;
    /**
     * 数据源ID
     */
    private Long datasourceId;

    /**
     * 系统
     */
    private String taskSystem;

    /**
     * 主题
     */
    private String theme;

    /**
     * 偏移量
     */
    private Integer offset;


    /**
     * 数据日期
     *
     */

    private String dataDate;


    /**
     * jobKey
     */

    private String jobKey;
    /**
     * @RequirementName: 监管调度平台对接ESB微信公众号短信平台需求
     * @Developer: 周敬坤
     * @ModifiedDate: 2025-03-19
     * @ModificationDescription: JLB_W2025020608_监管调度平台对接ESB微信公众号短信平台需求。
     */

    private String notificationCompleted;

    private String notificationFailed;

}
