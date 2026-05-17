package com.example.urgs_api.metric.controller;

import com.example.urgs_api.metric.dto.MetricTrendQuery;
import com.example.urgs_api.metric.dto.MetricTrendVO;
import com.example.urgs_api.metric.dto.MetricTypeRequest;
import com.example.urgs_api.metric.dto.MetricTypeVO;
import com.example.urgs_api.metric.service.MetricService;
import com.example.urgs_api.system.model.SysSystem;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/metrics")
public class MetricController {

    @Autowired
    private MetricService metricService;

    @GetMapping("/types")
    public List<MetricTypeVO> getMetricTypes(@RequestParam String systemId) {
        return metricService.getMetricTypes(systemId);
    }

    @GetMapping("/trend")
    public List<MetricTrendVO> getTrend(MetricTrendQuery query) {
        return metricService.getTrend(query);
    }

    @GetMapping("/systems")
    public List<SysSystem> getSystems(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return metricService.getSystemsWithMetrics(userId);
    }

    @GetMapping("/admin/systems")
    public List<SysSystem> getConfigSystems(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        return metricService.getConfigSystems(userId);
    }

    @GetMapping("/admin/types")
    public List<MetricTypeVO> listMetricTypesForConfig(@RequestParam(required = false) String systemId) {
        return metricService.listMetricTypesForConfig(systemId);
    }

    @PostMapping("/admin/types")
    public MetricTypeVO createMetricType(@RequestBody MetricTypeRequest request) {
        return metricService.createMetricType(request);
    }

    @PutMapping("/admin/types/{id}")
    public ResponseEntity<MetricTypeVO> updateMetricType(@PathVariable Long id,
                                                         @RequestBody MetricTypeRequest request) {
        MetricTypeVO result = metricService.updateMetricType(id, request);
        return result == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(result);
    }

    @DeleteMapping("/admin/types/{id}")
    public ResponseEntity<Void> deleteMetricType(@PathVariable Long id) {
        return metricService.deleteMetricType(id) ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}
