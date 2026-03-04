package com.example.urgs_api.marketplace.enums;

public enum AssignMode {
    OPEN("开放领取"),
    COMPETE("竞争竞标"),
    ASSIGN("定向指派");

    private final String desc;

    AssignMode(String desc) {
        this.desc = desc;
    }

    public String getDesc() {
        return desc;
    }
}
