package com.example.urgs_api.marketplace.enums;

public enum TaskStatus {
    OPEN("待承接"),
    READY("待开始"),
    IN_PROGRESS("处理中"),
    PAUSED("已暂停"),
    WAITING_REVIEW("待审核"),
    COMPLETED("已完成"),
    REWORK("退回修改"),
    CANCELLED("已取消");

    private final String desc;

    TaskStatus(String desc) {
        this.desc = desc;
    }

    public String getDesc() {
        return desc;
    }
}
