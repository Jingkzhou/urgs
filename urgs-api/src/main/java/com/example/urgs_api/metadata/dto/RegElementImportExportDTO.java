package com.example.urgs_api.metadata.dto;

import com.alibaba.excel.annotation.ExcelProperty;
import lombok.Data;

/**
 * 报表字段/指标导入导出 DTO
 * 用于详情 Sheet：报表字段及指标数据传输
 */
@Data
public class RegElementImportExportDTO {

    @ExcelProperty(value = "序号", index = 0)
    private Integer sortOrder;

    @ExcelProperty(value = "类型", index = 1)
    private String type;

    @ExcelProperty(value = "名称", index = 2)
    private String name;

    @ExcelProperty(value = "中文名", index = 3)
    private String cnName;

    @ExcelProperty(value = "数据类型", index = 4)
    private String dataType;

    @ExcelProperty(value = "长度", index = 5)
    private Integer length;

    @ExcelProperty(value = "是否主键", index = 6)
    private Integer isPk;

    @ExcelProperty(value = "允许为空", index = 7)
    private Integer nullable;

    @ExcelProperty(value = "计算公式", index = 8)
    private String formula;

    @ExcelProperty(value = "取数SQL", index = 9)
    private String fetchSql;

    @ExcelProperty(value = "引用码表", index = 10)
    private String codeTableCode;

    @ExcelProperty(value = "值域", index = 11)
    private String valueRange;

    @ExcelProperty(value = "校验规则", index = 12)
    private String validationRule;

    @ExcelProperty(value = "发文号", index = 13)
    private String dispatchNo;

    @ExcelProperty(value = "文档标题", index = 14)
    private String documentTitle;

    @ExcelProperty(value = "生效日期", index = 15)
    private String effectiveDate;

    @ExcelProperty(value = "业务口径", index = 16)
    private String businessCaliber;

    @ExcelProperty(value = "填报说明", index = 17)
    private String fillInstruction;

    @ExcelProperty(value = "研发备注", index = 18)
    private String devNotes;

    @ExcelProperty(value = "自动取数状态", index = 19)
    private String autoFetchStatus;

    @ExcelProperty(value = "负责人", index = 20)
    private String owner;

    @ExcelProperty(value = "状态", index = 21)
    private Integer status;

    @ExcelProperty(value = "是否初始化项", index = 22)
    private Integer isInit;

    @ExcelProperty(value = "是否归并公式项", index = 23)
    private Integer isMergeFormula;

    @ExcelProperty(value = "是否填报业务项", index = 24)
    private Integer isFillBusiness;

    @ExcelProperty(value = "代码片段", index = 25)
    private String codeSnippet;
}
