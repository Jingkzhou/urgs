package com.example.urgs_api.marketplace.enums;

public enum WorkStatus {
    DRAFT("草稿"),
    PUBLISHED("已发布"),
    ACTIVE("进行中"),
    PAUSED("已暂停"),
    ACCEPTANCE("待验收"),
    COMPLETED("已完成"),
    CANCELLED("已取消");

    private final String desc;

    WorkStatus(String desc) {
        this.desc = desc;
    }

    public String getDesc() {
        return desc;
    }
}
