package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("reg_element_query_config")
public class RegElementQueryConfig {
    @TableId(type = IdType.AUTO)
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    private Long id;

    @TableField("reg_element_id")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    private Long regElementId;

    private Integer enabled;

    @TableField("query_mode")
    private String queryMode;

    @TableField("data_source_id")
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    @com.fasterxml.jackson.databind.annotation.JsonSerialize(using = com.fasterxml.jackson.databind.ser.std.ToStringSerializer.class)
    private Long dataSourceId;

    @TableField("model_table_id")
    private String modelTableId;

    @TableField("date_field_id")
    private String dateFieldId;

    @TableField("org_code_field_id")
    private String orgCodeFieldId;

    @TableField("org_name_field_id")
    private String orgNameFieldId;

    @TableField("metric_code_field_id")
    private String metricCodeFieldId;

    @TableField("value_field_id")
    private String valueFieldId;

    @TableField("default_return_field_ids")
    private String defaultReturnFieldIds;

    @TableField("filter_field_ids")
    private String filterFieldIds;

    @TableField("sort_field_ids")
    private String sortFieldIds;

    @TableField("mask_field_ids")
    private String maskFieldIds;

    @TableField("detail_max_rows")
    private Integer detailMaxRows;

    @TableField("create_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createTime;

    @TableField("update_time")
    @JsonFormat(pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updateTime;
}
