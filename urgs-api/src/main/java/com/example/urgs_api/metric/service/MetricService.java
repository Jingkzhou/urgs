package com.example.urgs_api.metric.service;

import com.example.urgs_api.metric.dto.MetricTrendQuery;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.dto.MetricTypeRequest;
import com.example.urgs_api.metric.dto.MetricTypeVO;
import com.example.urgs_api.system.model.SysSystem;
import java.util.List;

public interface MetricService {
    List<MetricTypeVO> getMetricTypes(String systemId);
    List<MetricTrendVO> getTrend(MetricTrendQuery query);
    List<SysSystem> getSystemsWithMetrics(Long userId);
    List<SysSystem> getConfigSystems(Long userId);
    List<MetricTypeVO> listMetricTypesForConfig(String systemId);
    MetricTypeVO createMetricType(MetricTypeRequest request);
    MetricTypeVO updateMetricType(Long id, MetricTypeRequest request);
    boolean deleteMetricType(Long id);
}
