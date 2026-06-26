package com.example.urgs_api.quartz.domain.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;
import com.example.urgs_api.quartz.support.domain.BaseEntity;

import java.util.Date;


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
@TableName("t_quartz_task_status")
public class QuartzTaskStatusEntity extends BaseEntity {
    /**
     * 计划ID
     */
    private long planId;
    /**
     * 数据日期
     */
    private String dataDate;

    /**
     * 状态 1.等待执行，2.执行中，3.成功，4.失败
     */
    private int status;
    /**
     * 开始时间
     */
    private Date beginTime;
    /**
     * 结束时间
     */
    private Date endTime;
    /**
     * 执行描述
     */
    private String msg;

    /**
     * 本次执行选择的数据池ID
     */
    private Long executePoolId;

    /**
     * 本次执行选择的数据池名称
     */
    private String executePoolName;

    /**
     * 本次执行选择的数据源ID
     */
    private Long executeDatasourceId;

    /**
     * 本次执行选择的数据源名称
     */
    private String executeDatasourceName;
}
