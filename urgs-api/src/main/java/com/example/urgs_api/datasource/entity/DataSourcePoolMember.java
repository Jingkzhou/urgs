package com.example.urgs_api.datasource.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_datasource_pool_member")
public class DataSourcePoolMember {

    @TableId(type = IdType.AUTO)
    private Long id;

    private Long poolId;

    private Long datasourceId;

    private Integer enabled;

    private Integer weight;

    private Integer maxConcurrency;

    private Integer sortNo;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;

    @TableField(exist = false)
    private String datasourceName;

    @TableField(exist = false)
    private String typeName;

    @TableField(exist = false)
    private String typeCode;

    @TableField(exist = false)
    private String category;
}
