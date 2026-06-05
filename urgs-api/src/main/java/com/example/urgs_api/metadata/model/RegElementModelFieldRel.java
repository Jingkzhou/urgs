package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("reg_element_model_field_rel")
public class RegElementModelFieldRel {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("reg_element_id")
    private Long regElementId;

    @TableField("model_table_id")
    private String modelTableId;

    @TableField("model_field_id")
    private String modelFieldId;

    @TableField("create_time")
    private LocalDateTime createTime;
}
