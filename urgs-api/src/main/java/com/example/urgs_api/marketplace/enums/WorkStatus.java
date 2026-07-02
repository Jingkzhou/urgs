package com.example.urgs_api.marketplace.enums;

public enum WorkStatus {
    DRAFT("草稿"),
    PUBLISHED("已发布"),
    ASSIGNED("已承接"),
    IN_PROGRESS("进行中"),
    PAUSED("已暂停"),
    REVIEW("待验收"),
    COMPLETED("已完成"),
    REJECTED("退回修改"),
    CANCELLED("已取消");

    private final String desc;

    WorkStatus(String desc) {
        this.desc = desc;
    }

    public String getDesc() {
        return desc;
    }
}
