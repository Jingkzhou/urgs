package com.example.urgs_api.metadata.dto;

/**
 * 物理模型 DDL 导入结果
 */
public class ModelDdlImportResult {
    private int tableCount;
    private int fieldCount;
    private String language;

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

    public String getLanguage() {
        return language;
    }

    public void setLanguage(String language) {
        this.language = language;
    }
}
