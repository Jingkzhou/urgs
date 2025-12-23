package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

@Data
public class LineageExportDTO {
    @ExcelProperty("源表")
    private String sourceTable;

    @ExcelProperty("源字段")
    private String sourceColumn;

    @ExcelProperty("关系类型")
    private String relationType;

    @ExcelProperty("目标表")
    private String targetTable;

    @ExcelProperty("目标字段")
    private String targetColumn;
}
