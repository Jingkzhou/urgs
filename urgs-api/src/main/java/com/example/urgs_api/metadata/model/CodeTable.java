package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("code_table")
/**
 * 码表实体
 * 对应表: code_table
 */
public class CodeTable {
    @TableId(type = IdType.ASSIGN_ID)
    private String id;
    private String tableCode;
    private String tableName;
    private String systemCode;
    private String description;
    private String standard;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;

    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String reqId;

    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    @com.fasterxml.jackson.annotation.JsonFormat(pattern = "yyyy-MM-dd")
    private java.time.LocalDate plannedDate;

    @com.baomidou.mybatisplus.annotation.TableField(exist = false)
    private String changeDescription;
}
