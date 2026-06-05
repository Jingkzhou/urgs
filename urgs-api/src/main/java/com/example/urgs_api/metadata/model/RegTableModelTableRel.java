package com.example.urgs_api.metadata.model;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("reg_table_model_table_rel")
public class RegTableModelTableRel {
    @TableId(type = IdType.AUTO)
    private Long id;

    @TableField("reg_table_id")
    private Long regTableId;

    @TableField("model_table_id")
    private String modelTableId;

    @TableField("create_time")
    private LocalDateTime createTime;
}
