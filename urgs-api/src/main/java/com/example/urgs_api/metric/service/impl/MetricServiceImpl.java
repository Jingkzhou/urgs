package com.example.urgs_api.metric.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metric.dto.MetricTrendQuery;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.dto.MetricTypeRequest;
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
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Locale;
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
    private static final Set<String> SUPPORTED_CHART_TYPES = Set.of("line", "area", "bar", "pie");

    @Override
    public List<MetricTypeVO> getMetricTypes(String systemId) {
        LambdaQueryWrapper<MetricType> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(MetricType::getSystemId, systemId)
               .eq(MetricType::getStatus, 1)
               .orderByAsc(MetricType::getSortOrder);

        return metricTypeMapper.selectList(wrapper).stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    @Override
    public List<MetricTrendVO> getTrend(MetricTrendQuery query) {
        if (query.getSystemId() == null || query.getTypeCode() == null) {
            return Collections.emptyList();
        }

        String startTime = query.getStartTime();
        String endTime = query.getEndTime();

        String datePattern;
        if ("DAY".equalsIgnoreCase(query.getGranularity())) {
            datePattern = "%Y-%m-%d";
        } else if ("MONTH".equalsIgnoreCase(query.getGranularity())) {
            datePattern = "%Y-%m";
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

    @Override
    public List<SysSystem> getConfigSystems(Long userId) {
        return sysSystemService.getSystems(userId, true);
    }

    @Override
    public List<MetricTypeVO> listMetricTypesForConfig(String systemId) {
        LambdaQueryWrapper<MetricType> wrapper = new LambdaQueryWrapper<>();
        if (StringUtils.hasText(systemId)) {
            wrapper.eq(MetricType::getSystemId, systemId);
        }
        wrapper.orderByAsc(MetricType::getSystemId)
                .orderByAsc(MetricType::getSortOrder)
                .orderByDesc(MetricType::getUpdatedAt);
        return metricTypeMapper.selectList(wrapper).stream()
                .map(this::toVO)
                .collect(Collectors.toList());
    }

    @Override
    public MetricTypeVO createMetricType(MetricTypeRequest request) {
        MetricType entity = new MetricType();
        applyRequest(entity, request);
        entity.setCreatedAt(LocalDateTime.now());
        entity.setUpdatedAt(LocalDateTime.now());
        metricTypeMapper.insert(entity);
        return toVO(entity);
    }

    @Override
    public MetricTypeVO updateMetricType(Long id, MetricTypeRequest request) {
        MetricType entity = metricTypeMapper.selectById(id);
        if (entity == null) {
            return null;
        }
        applyRequest(entity, request);
        entity.setUpdatedAt(LocalDateTime.now());
        metricTypeMapper.updateById(entity);
        return toVO(metricTypeMapper.selectById(id));
    }

    @Override
    public boolean deleteMetricType(Long id) {
        return metricTypeMapper.deleteById(id) > 0;
    }

    private void applyRequest(MetricType entity, MetricTypeRequest request) {
        entity.setSystemId(requireText(request.getSystemId(), "systemId"));
        entity.setTypeCode(requireText(request.getTypeCode(), "typeCode"));
        entity.setTypeName(requireText(request.getTypeName(), "typeName"));
        entity.setUnit(trimToNull(request.getUnit()));
        entity.setColor(StringUtils.hasText(request.getColor()) ? request.getColor().trim() : "#ef4444");
        entity.setSortOrder(request.getSortOrder() == null ? 0 : request.getSortOrder());
        entity.setStatus(request.getStatus() == null ? 1 : request.getStatus());

        String supported = normalizeSupportedChartTypes(request.getSupportedChartTypes());
        String defaultType = normalizeChartType(request.getDefaultChartType(), "area");
        if (!Arrays.asList(supported.split(",")).contains(defaultType)) {
            supported = defaultType + "," + supported;
        }
        entity.setDefaultChartType(defaultType);
        entity.setSupportedChartTypes(supported);
    }

    private MetricTypeVO toVO(MetricType mt) {
        MetricTypeVO vo = new MetricTypeVO();
        vo.setId(mt.getId());
        vo.setSystemId(mt.getSystemId());
        vo.setTypeCode(mt.getTypeCode());
        vo.setTypeName(mt.getTypeName());
        vo.setUnit(mt.getUnit());
        vo.setColor(mt.getColor());
        vo.setDefaultChartType(StringUtils.hasText(mt.getDefaultChartType()) ? mt.getDefaultChartType() : "area");
        vo.setSupportedChartTypes(StringUtils.hasText(mt.getSupportedChartTypes()) ? mt.getSupportedChartTypes() : "area,line,bar");
        vo.setSortOrder(mt.getSortOrder());
        vo.setStatus(mt.getStatus());
        return vo;
    }

    private String requireText(String value, String fieldName) {
        if (!StringUtils.hasText(value)) {
            throw new IllegalArgumentException(fieldName + " 不能为空");
        }
        return value.trim();
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String normalizeSupportedChartTypes(String value) {
        String raw = StringUtils.hasText(value) ? value : "area,line,bar";
        String normalized = Arrays.stream(raw.split(","))
                .map(type -> normalizeChartType(type, null))
                .filter(StringUtils::hasText)
                .distinct()
                .collect(Collectors.joining(","));
        return StringUtils.hasText(normalized) ? normalized : "area,line,bar";
    }

    private String normalizeChartType(String value, String fallback) {
        if (!StringUtils.hasText(value)) {
            return fallback;
        }
        String normalized = value.trim().toLowerCase(Locale.ROOT);
        if (!SUPPORTED_CHART_TYPES.contains(normalized)) {
            throw new IllegalArgumentException("不支持的图表类型: " + value);
        }
        return normalized;
    }
}
