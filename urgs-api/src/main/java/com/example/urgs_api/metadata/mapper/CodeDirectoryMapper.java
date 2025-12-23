package com.example.urgs_api.metadata.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metadata.model.CodeDirectory;
import org.apache.ibatis.annotations.Mapper;

@Mapper
/**
 * 代码目录Mapper接口
 */
public interface CodeDirectoryMapper extends BaseMapper<CodeDirectory> {
}
