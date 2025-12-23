package com.example.urgs_api.datasource.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import com.baomidou.mybatisplus.annotation.TableField;
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

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCategory() {
        return category;
    }

    public void setCategory(String category) {
        this.category = category;
    }

    public List<Map<String, Object>> getFormSchema() {
        return formSchema;
    }

    public void setFormSchema(List<Map<String, Object>> formSchema) {
        this.formSchema = formSchema;
    }

    public LocalDateTime getCreateTime() {
        return createTime;
    }

    public void setCreateTime(LocalDateTime createTime) {
        this.createTime = createTime;
    }
}
