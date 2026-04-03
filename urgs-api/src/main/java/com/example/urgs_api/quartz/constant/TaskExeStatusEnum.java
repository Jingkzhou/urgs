package com.example.urgs_api.quartz.constant;

/**
 * 任务执行状态枚举
 */
public enum TaskExeStatusEnum {

    WAITING(1, "等待执行"),
    RUNNING(2, "执行中"),
    SUCCESS(3, "执行成功"),
    FAILED(4, "执行失败");

    public static final String INFO = "1:等待执行，2:执行中，3:执行成功，4:执行失败";

    private Integer code;

    private String desc;

    TaskExeStatusEnum(Integer code, String desc) {
        this.code = code;
        this.desc = desc;
    }

    public Integer getCode() {
        return code;
    }

    public String getDesc() {
        return desc;
    }
}
