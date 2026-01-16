package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

@Data
/**
 * 代码目录导入导出对象
 * 用于Excel导入导出代码目录数据
 */
public class CodeDirectoryImportExportDTO {
    @ExcelProperty("码表编号")
    private String tableCode;

    @ExcelProperty("码表名称")
    private String tableName;

    @ExcelProperty("排序号")
    private Integer sortOrder;

    @ExcelProperty("代码")
    private String code;

    @ExcelProperty("名称")
    private String name;

    @ExcelProperty("上级代码")
    private String parentCode;

    @ExcelProperty("代码级别")
    private String level;

    @ExcelProperty("特别说明")
    private String description;

    @ExcelProperty("启用日期")
    private String startDate;

    @ExcelProperty("废止日期")
    private String endDate;

    @ExcelProperty("执行标准")
    private String standard;

    @ExcelProperty("系统代码")
    private String systemCode;

    public String getTableCode() {
        return tableCode;
    }

    public void setTableCode(String tableCode) {
        this.tableCode = tableCode;
    }

    public String getTableName() {
        return tableName;
    }

    public void setTableName(String tableName) {
        this.tableName = tableName;
    }

    public Integer getSortOrder() {
        return sortOrder;
    }

    public void setSortOrder(Integer sortOrder) {
        this.sortOrder = sortOrder;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getParentCode() {
        return parentCode;
    }

    public void setParentCode(String parentCode) {
        this.parentCode = parentCode;
    }

    public String getLevel() {
        return level;
    }

    public void setLevel(String level) {
        this.level = level;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public String getStartDate() {
        return startDate;
    }

    public void setStartDate(String startDate) {
        this.startDate = startDate;
    }

    public String getEndDate() {
        return endDate;
    }

    public void setEndDate(String endDate) {
        this.endDate = endDate;
    }

    public String getStandard() {
        return standard;
    }

    public void setStandard(String standard) {
        this.standard = standard;
    }

    public String getSystemCode() {
        return systemCode;
    }

    public void setSystemCode(String systemCode) {
        this.systemCode = systemCode;
    }
}
