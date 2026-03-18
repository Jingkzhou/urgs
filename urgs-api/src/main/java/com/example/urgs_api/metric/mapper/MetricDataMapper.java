package com.example.urgs_api.metric.mapper;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.entity.MetricData;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.time.LocalDateTime;
import java.util.List;

@Mapper
public interface MetricDataMapper extends BaseMapper<MetricData> {

    List<MetricTrendVO> queryTrend(@Param("systemId") String systemId,
                                   @Param("typeCode") String typeCode,
                                   @Param("startTime") LocalDateTime startTime,
                                   @Param("endTime") LocalDateTime endTime,
                                   @Param("datePattern") String datePattern);
}
