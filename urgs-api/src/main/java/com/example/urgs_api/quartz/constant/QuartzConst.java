package com.example.urgs_api.quartz.constant;

/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/13 0013 下午 15:21
 * @since JDK1.8
 */
public class QuartzConst {
    public static final String QUARTZ_PARAMS_KEY="TASK_PARAMS";
    public static final String JOB_KEY_PREFIX="TASK_";
    public static final String TRIGGER_KEY_PREFIX="TRIGGER_";

    /**
     * 等待超时阈值（分钟），超过此时间仍为等待状态则视为等待超时
     */
    public static final long WAITING_TIMEOUT_MINUTES = 60;
}
