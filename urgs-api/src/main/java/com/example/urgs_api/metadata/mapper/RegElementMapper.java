package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.RegElement;
import org.apache.ibatis.annotations.Mapper;

@Mapper
/**
 * 监管元素Mapper接口
 */
public interface RegElementMapper extends BaseMapper<RegElement> {
}
