package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;

@ColumnWidth(20)
/**
 * 模型表导出对象
 * 用于Excel导出模型表基本信息
 */
public class ModelTableExportDTO {

    @ExcelProperty("表名")
    private String name;

    @ExcelProperty("中文名称")
    private String cnName;

    @ExcelProperty("科目号")
    private String subjectCode;

    @ExcelProperty("科目中文名")
    private String subjectName;

    @ExcelProperty("监管主题")
    private String theme;

    @ExcelProperty("业务范围")
    private String businessScope;

    @ExcelProperty("报送频度")
    private String freq;

    @ExcelProperty("版本")
    private String version;

    @ExcelProperty("保留时间")
    private String retentionTime;

    @ExcelProperty("备注")
    private String remark;

    // Getters and Setters
    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCnName() {
        return cnName;
    }

    public void setCnName(String cnName) {
        this.cnName = cnName;
    }

    public String getSubjectCode() {
        return subjectCode;
    }

    public void setSubjectCode(String subjectCode) {
        this.subjectCode = subjectCode;
    }

    public String getSubjectName() {
        return subjectName;
    }

    public void setSubjectName(String subjectName) {
        this.subjectName = subjectName;
    }

    public String getTheme() {
        return theme;
    }

    public void setTheme(String theme) {
        this.theme = theme;
    }

    public String getBusinessScope() {
        return businessScope;
    }

    public void setBusinessScope(String businessScope) {
        this.businessScope = businessScope;
    }

    public String getFreq() {
        return freq;
    }

    public void setFreq(String freq) {
        this.freq = freq;
    }

    public String getVersion() {
        return version;
    }

    public void setVersion(String version) {
        this.version = version;
    }

    public String getRetentionTime() {
        return retentionTime;
    }

    public void setRetentionTime(String retentionTime) {
        this.retentionTime = retentionTime;
    }

    public String getRemark() {
        return remark;
    }

    public void setRemark(String remark) {
        this.remark = remark;
    }
}
