package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.CodeTable;
import org.apache.ibatis.annotations.Mapper;

@Mapper
/**
 * 码表Mapper接口
 */
public interface CodeTableMapper extends BaseMapper<CodeTable> {
}
