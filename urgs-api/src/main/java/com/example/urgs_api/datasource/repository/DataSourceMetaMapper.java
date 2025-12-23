package com.example.urgs_api.datasource.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface DataSourceMetaMapper extends BaseMapper<DataSourceMeta> {
}
