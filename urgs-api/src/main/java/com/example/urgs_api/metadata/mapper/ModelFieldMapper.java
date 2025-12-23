package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.ModelField;
import org.apache.ibatis.annotations.Mapper;

@Mapper
/**
 * 模型字段Mapper接口
 */
public interface ModelFieldMapper extends BaseMapper<ModelField> {
}
