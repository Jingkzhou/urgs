package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.Map;

@Data
@TableName(value = "sys_datasource_config", autoResultMap = true)
public class DataSourceConfig {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String name;

    private Long metaId;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private Map<String, Object> connectionParams;

    private Integer status;

    private LocalDateTime createTime;
}
