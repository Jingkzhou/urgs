package com.example.executor.quartz.constant;

public enum TaskStatusEnum {
    NORMAL(0, "正常"),
    PAUSE(1, "暂停");

    private final Integer status;
    private final String desc;

    TaskStatusEnum(Integer status, String desc) {
        this.status = status;
        this.desc = desc;
    }

    public Integer getStatus() {
        return status;
    }

    public String getDesc() {
        return desc;
    }
}
