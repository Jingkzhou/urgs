package com.example.urgs_api.metric.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metric.entity.MetricType;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Select;
import java.util.List;

@Mapper
public interface MetricTypeMapper extends BaseMapper<MetricType> {

    @Select("SELECT DISTINCT system_id FROM t_metric_type WHERE status = 1")
    List<String> selectDistinctSystemIds();
}
