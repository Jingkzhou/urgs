package com.example.urgs_api.marketplace.enums;

public enum TaskStatus {
    OPEN("开放领取"),
    APPLIED("已申请竞标"),
    ASSIGNED("已指派/已领取"),
    IN_PROGRESS("开发/处理中"),
    PAUSED("已暂停"),
    REVIEW("待审核"),
    COMPLETED("已完成"),
    REJECTED("退回修改"),
    CANCELLED("已取消"),
    OVERDUE("已逾期");

    private final String desc;

    TaskStatus(String desc) {
        this.desc = desc;
    }

    public String getDesc() {
        return desc;
    }
}
