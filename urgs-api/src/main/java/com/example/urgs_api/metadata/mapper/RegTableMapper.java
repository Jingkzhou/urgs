package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.RegTable;
import org.apache.ibatis.annotations.Mapper;

@Mapper
/**
 * 监管报表Mapper接口
 */
public interface RegTableMapper extends BaseMapper<RegTable> {
}
