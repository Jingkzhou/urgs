package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;
import com.alibaba.excel.annotation.ExcelProperty;
import com.alibaba.excel.annotation.ExcelIgnore;

@Data
@TableName("reg_element")
/**
 * 监管元素实体（指标/字段）
 * 对应表: sys_reg_element
 */
public class RegElement {

    @TableId(type = IdType.AUTO)
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    @ExcelProperty(value = "系统ID", index = 0)
    private Long id;

    @TableField("table_id")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    @ExcelIgnore
    private Long tableId;

    /**
     * 类型: FIELD / INDICATOR
     */
    @ExcelProperty(value = "类型", index = 1)
    private String type;

    @ExcelProperty(value = "名称", index = 2)
    private String name;

    @TableField("cn_name")
    @ExcelProperty(value = "中文名", index = 3)
    private String cnName;

    @TableField("data_type")
    @ExcelProperty(value = "数据类型", index = 5)
    private String dataType;

    @ExcelProperty(value = "长度", index = 6)
    private Integer length;

    @TableField("is_pk")
    @ExcelProperty(value = "是否主键", index = 7)
    private Integer isPk;

    @ExcelProperty(value = "允许为空", index = 8)
    private Integer nullable;

    @ExcelProperty(value = "计算公式", index = 9)
    private String formula;

    @TableField("fetch_sql")
    @ExcelProperty(value = "取数SQL", index = 10)
    private String fetchSql;

    /**
     * 代码片段 (指标类型专用)
     */
    @TableField("code_snippet")
    @ExcelProperty(value = "代码片段", index = 27)
    private String codeSnippet;

    @TableField("code_table_code")
    @ExcelProperty(value = "引用码表", index = 11)
    private String codeTableCode;

    @TableField("value_range")
    @ExcelProperty(value = "值域", index = 12)
    private String valueRange;

    @TableField("validation_rule")
    @ExcelProperty(value = "校验规则", index = 13)
    private String validationRule;

    @ExcelProperty(value = "发文号", index = 14)
    @TableField("dispatch_no")
    private String dispatchNo;

    @TableField("effective_date")
    @ExcelProperty(value = "生效日期", index = 16)
    private LocalDate effectiveDate;

    @TableField("business_caliber")
    @ExcelProperty(value = "业务口径", index = 17)
    private String businessCaliber;

    @TableField("fill_instruction")
    @ExcelProperty(value = "填报说明", index = 18)
    private String fillInstruction;

    @TableField("dev_notes")
    @ExcelProperty(value = "研发备注", index = 19)
    private String devNotes;

    @TableField("auto_fetch_status")
    @ExcelProperty(value = "自动取数", index = 20)
    private String autoFetchStatus;

    @ExcelProperty(value = "负责人", index = 21)
    private String owner;

    @ExcelProperty(value = "状态(1正常0停用)", index = 22)
    private Integer status;

    @TableField("sort_order")
    @ExcelProperty(value = "序号", index = 23)
    private Integer sortOrder;

    /**
     * 是否初始化项 (0: 否, 1: 是)
     */
    @TableField("is_init")
    @ExcelProperty(value = "是否初始化项", index = 24)
    private Integer isInit;

    /**
     * 是否归并公式项 (0: 否, 1: 是)
     */
    @TableField("is_merge_formula")
    @ExcelProperty(value = "是否归并公式项", index = 25)
    private Integer isMergeFormula;

    /**
     * 是否填报业务项 (0: 否, 1: 是)
     */
    @TableField("is_fill_business")
    @ExcelProperty(value = "是否填报业务项", index = 26)
    private Integer isFillBusiness;

    @TableField("create_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    @TableField("update_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updateTime;
    @TableField(exist = false)
    private String reqId;

    @TableField(exist = false)
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate plannedDate;

    @TableField(exist = false)
    private String changeDescription;
}
