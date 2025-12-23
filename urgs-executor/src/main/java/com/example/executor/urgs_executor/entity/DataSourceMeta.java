package com.example.executor.urgs_executor.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Data
@TableName(value = "sys_datasource_meta", autoResultMap = true)
public class DataSourceMeta {
    @TableId(type = IdType.AUTO)
    private Long id;

    private String code;

    private String name;

    private String category;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private List<Map<String, Object>> formSchema;

    private LocalDateTime createTime;
}
