package com.example.executor.quartz.constant;

public enum TaskExeStatusEnum {

    WAITING(1, "等待执行"),
    RUNNING(2, "执行中"),
    SUCCESS(3, "成功"),
    FAILED(4, "失败");

    private final Integer code;
    private final String desc;

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
