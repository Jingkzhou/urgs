package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;

/**
 * 模型导入导出对象
 * 用于Excel导入导出模型字段定义
 */
public class ModelImportExportDTO {

    @ExcelProperty("表名")
    private String tableName;

    @ExcelProperty("字段名")
    private String fieldName;

    @ExcelProperty("字段中文名")
    private String fieldCnName;

    @ExcelProperty("类型")
    private String type;

    @ExcelProperty("是否主键")
    private String isPk; // "是" or "否"

    @ExcelProperty("是否可空")
    private String nullable; // "是" or "否"

    @ExcelProperty("值域")
    private String domain;

    @ExcelProperty("备注")
    private String remark;

    public String getTableName() {
        return tableName;
    }

    public void setTableName(String tableName) {
        this.tableName = tableName;
    }

    public String getFieldName() {
        return fieldName;
    }

    public void setFieldName(String fieldName) {
        this.fieldName = fieldName;
    }

    public String getFieldCnName() {
        return fieldCnName;
    }

    public void setFieldCnName(String fieldCnName) {
        this.fieldCnName = fieldCnName;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getIsPk() {
        return isPk;
    }

    public void setIsPk(String isPk) {
        this.isPk = isPk;
    }

    public String getNullable() {
        return nullable;
    }

    public void setNullable(String nullable) {
        this.nullable = nullable;
    }

    public String getDomain() {
        return domain;
    }

    public void setDomain(String domain) {
        this.domain = domain;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }
}
