package com.example.urgs_api.metadata.dto;

/**
 * 模型同步结果
 */
public class ModelSyncResult {
    private int tableCount;
    private int fieldCount;
    private int ownerCount;

    public int getTableCount() {
        return tableCount;
    }

    public void setTableCount(int tableCount) {
        this.tableCount = tableCount;
    }

    public int getFieldCount() {
        return fieldCount;
    }

    public void setFieldCount(int fieldCount) {
        this.fieldCount = fieldCount;
    }

    public int getOwnerCount() {
        return ownerCount;
    }

    public void setOwnerCount(int ownerCount) {
        this.ownerCount = ownerCount;
    }
}
