package com.example.urgs_api.issue.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.write.style.ColumnWidth;
import lombok.Data;

@Data
public class IssueExportDTO {
    @ExcelProperty("问题ID")
    @ColumnWidth(20)
    private String id;

    @ExcelProperty("问题标题")
    @ColumnWidth(40)
    private String title;

    @ExcelProperty("问题描述")
    @ColumnWidth(50)
    private String description;

    @ExcelProperty("涉及系统")
    @ColumnWidth(15)
    private String system;

    @ExcelProperty("解决方案")
    @ColumnWidth(50)
    private String solution;

    @ExcelProperty("发生时间")
    @ColumnWidth(20)
    private String occurTime;

    @ExcelProperty("提出人")
    @ColumnWidth(12)
    private String reporter;

    @ExcelProperty("解决时间")
    @ColumnWidth(20)
    private String resolveTime;

    @ExcelProperty("处理人")
    @ColumnWidth(12)
    private String handler;

    @ExcelProperty("问题类型")
    @ColumnWidth(15)
    private String issueType;

    @ExcelProperty("状态")
    @ColumnWidth(10)
    private String status;

    @ExcelProperty("工时(小时)")
    @ColumnWidth(12)
    private String workHours;
}
