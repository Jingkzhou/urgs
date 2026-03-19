package com.example.urgs_api.metric.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metric.dto.MetricTrendQuery;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.dto.MetricTypeVO;
import com.example.urgs_api.metric.entity.MetricType;
import com.example.urgs_api.metric.entity.MetricData;
import com.example.urgs_api.metric.mapper.MetricDataMapper;
import com.example.urgs_api.metric.mapper.MetricTypeMapper;
import com.example.urgs_api.metric.service.MetricService;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class MetricServiceImpl implements MetricService {

    @Autowired
    private MetricTypeMapper metricTypeMapper;

    @Autowired
    private MetricDataMapper metricDataMapper;

    @Autowired
    private SysSystemService sysSystemService;

    private static final DateTimeFormatter DT_FORMATTER = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    @Override
    public List<MetricTypeVO> getMetricTypes(String systemId) {
        LambdaQueryWrapper<MetricType> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetricType::getSystemId, systemId)
               .eq(MetricType::getStatus, 1)
               .orderByAsc(MetricType::getSortOrder);

        return metricTypeMapper.selectList(wrapper).stream().map(mt -> {
            MetricTypeVO vo = new MetricTypeVO();
            vo.setTypeCode(mt.getTypeCode());
            vo.setTypeName(mt.getTypeName());
            vo.setUnit(mt.getUnit());
            vo.setColor(mt.getColor());
            vo.setSortOrder(mt.getSortOrder());
            return vo;
        }).collect(Collectors.toList());
    }

    @Override
    public List<MetricTrendVO> getTrend(MetricTrendQuery query) {
        if (query.getSystemId() == null || query.getTypeCode() == null) {
            return Collections.emptyList();
        }

        LocalDateTime startTime = LocalDateTime.parse(query.getStartTime(), DT_FORMATTER);
        LocalDateTime endTime = LocalDateTime.parse(query.getEndTime(), DT_FORMATTER);

        String datePattern;
        if ("DAY".equalsIgnoreCase(query.getGranularity())) {
            datePattern = "%Y-%m-%d";
        } else {
            datePattern = "%Y-%m-%d %H:00";
        }

        return metricDataMapper.queryTrend(query.getSystemId(), query.getTypeCode(),
                startTime, endTime, datePattern);
    }

    @Override
    public List<SysSystem> getSystemsWithMetrics(Long userId) {
        // Get all system_ids that have actual metric data
        List<Object> objs = metricDataMapper.selectObjs(new QueryWrapper<MetricData>().select("DISTINCT system_id"));
        if (objs.isEmpty()) {
            return Collections.emptyList();
        }
        
        List<String> metricSystemIds = objs.stream().map(Object::toString).collect(Collectors.toList());

        // Get user's accessible systems
        List<SysSystem> accessibleSystems = sysSystemService.getSystems(userId, false);

        // Intersect: only return systems the user can access AND that have metric data
        Set<String> metricIdSet = new java.util.HashSet<>(metricSystemIds);
        List<SysSystem> result = accessibleSystems.stream()
                .filter(s -> metricIdSet.contains(s.getClientId()))
                .collect(Collectors.toList());

        return result;
    }
}
