package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

/**
 * 报表导入导出 DTO
 * 用于第一个 Sheet：报表列表数据传输
 */
@Data
public class RegTableImportExportDTO {

    @ExcelProperty(value = "序号", index = 0)
    private Integer sortOrder;

    @ExcelProperty(value = "中文名/表名", index = 1)
    private String cnName; // 原index=1

    @ExcelProperty(value = "表名", index = 2)
    private String name; // 原index=0，现在往后移

    @ExcelProperty(value = "系统编码", index = 3)
    private String systemCode;

    @ExcelProperty(value = "科目编码", index = 4)
    private String subjectCode;

    @ExcelProperty(value = "科目名称", index = 5)
    private String subjectName;

    @ExcelProperty(value = "主题", index = 6)
    private String theme;

    @ExcelProperty(value = "报送频度", index = 7)
    private String frequency;

    @ExcelProperty(value = "取数来源", index = 8)
    private String sourceType;

    @ExcelProperty(value = "自动取数状态", index = 9)
    private String autoFetchStatus;

    @ExcelProperty(value = "发文号", index = 10)
    private String dispatchNo;

    @ExcelProperty(value = "填报说明", index = 11)
    private String fillInstruction;

    @ExcelProperty(value = "生效日期", index = 12)
    private String effectiveDate;

    @ExcelProperty(value = "业务口径", index = 13)
    private String businessCaliber;

    @ExcelProperty(value = "研发备注", index = 14)
    private String devNotes;

    @ExcelProperty(value = "负责人", index = 15)
    private String owner;
}
