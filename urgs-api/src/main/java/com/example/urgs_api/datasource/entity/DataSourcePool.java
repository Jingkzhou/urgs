package com.example.urgs_api.datasource.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("sys_datasource_pool")
public class DataSourcePool {

    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private String poolType;

    private String strategy;

    private Integer status;

    private String remark;

    private LocalDateTime createTime;

    private LocalDateTime updateTime;
}
