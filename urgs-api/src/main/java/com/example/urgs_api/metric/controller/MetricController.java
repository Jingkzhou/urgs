package com.example.urgs_api.metric.controller;

import com.example.urgs_api.metric.dto.MetricTrendQuery;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.dto.MetricTypeVO;
import com.example.urgs_api.metric.service.MetricService;
import com.example.urgs_api.system.model.SysSystem;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/metrics")
public class MetricController {

    @Autowired
    private MetricService metricService;

    @GetMapping("/systems")
    public List<SysSystem> getSystems(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return metricService.getSystemsWithMetrics(userId);
    }

    @GetMapping("/types")
    public List<MetricTypeVO> getMetricTypes(@RequestParam String systemId) {
        return metricService.getMetricTypes(systemId);
    }

    @GetMapping("/trend")
    public List<MetricTrendVO> getTrend(MetricTrendQuery query) {
        return metricService.getTrend(query);
    }
}
