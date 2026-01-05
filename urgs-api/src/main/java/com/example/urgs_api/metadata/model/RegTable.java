package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("sys_reg_table")
/**
 * 监管报表实体
 * 对应表: sys_reg_table
 */
public class RegTable {

    @TableId(type = IdType.AUTO)
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    private Long id;

    @TableField("sort_order")
    private Integer sortOrder;

    private String name;

    @TableField("cn_name")
    private String cnName;

    @TableField("system_code")
    private String systemCode;

    @TableField("subject_code")
    private String subjectCode;

    @TableField("subject_name")
    private String subjectName;

    private String theme;

    private String frequency;

    @TableField("source_type")
    private String sourceType;

    @TableField("auto_fetch_status")
    private String autoFetchStatus;

    @TableField("document_no")
    private String documentNo;

    @TableField("document_title")
    private String documentTitle;

    @TableField("effective_date")
    private LocalDate effectiveDate;

    @TableField("business_caliber")
    private String businessCaliber;

    @TableField("dev_notes")
    private String devNotes;

    private String owner;

    private Integer status;

    @TableField("create_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    @TableField("update_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updateTime;
    @TableField(exist = false)
    private Long fieldCount;

    @TableField(exist = false)
    private Long indicatorCount;

    @TableField(exist = false)
    private String reqId;

    @TableField(exist = false)
    @JsonFormat(pattern = "yyyy-MM-dd")
    private LocalDate plannedDate;

    @TableField(exist = false)
    private String changeDescription;
}
