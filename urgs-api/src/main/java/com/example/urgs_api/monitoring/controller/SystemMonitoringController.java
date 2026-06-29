package com.example.urgs_api.monitoring.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.monitoring.dto.MonitoringDtos;
import com.example.urgs_api.monitoring.service.MonitorThresholdService;
import com.example.urgs_api.monitoring.service.SystemMonitoringService;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/system-monitor")
public class SystemMonitoringController {

    private final SystemMonitoringService monitoringService;
    private final MonitorThresholdService thresholdService;

    public SystemMonitoringController(SystemMonitoringService monitoringService,
                                      MonitorThresholdService thresholdService) {
        this.monitoringService = monitoringService;
        this.thresholdService = thresholdService;
    }

    @GetMapping("/overview")
    @RequirePermission("sys:monitor:query")
    public MonitoringDtos.Overview overview(
            @RequestParam(required = false) String targetType,
            @RequestParam(required = false) Long systemId,
            @RequestParam(required = false) Long envId,
            @RequestParam(required = false) String status) {
        return monitoringService.overview(targetType, systemId, envId, status);
    }

    @GetMapping("/servers")
    @RequirePermission("sys:monitor:query")
    public List<MonitoringDtos.ServerSummary> servers(
            @RequestParam(required = false) Long systemId,
            @RequestParam(required = false) Long envId,
            @RequestParam(required = false) String status,
            @RequestParam(defaultValue = "false") boolean includeDisabled) {
        return monitoringService.listServers(systemId, envId, status, includeDisabled);
    }

    @GetMapping("/servers/{assetId}/trend")
    @RequirePermission("sys:monitor:query")
    public List<MonitoringDtos.TrendPoint> serverTrend(
            @PathVariable Long assetId,
            @RequestParam(defaultValue = "24h") String range) {
        return monitoringService.serverTrend(assetId, range);
    }

    @GetMapping("/databases")
    @RequirePermission("sys:monitor:query")
    public List<MonitoringDtos.DatabaseSummary> databases(
            @RequestParam(required = false) Long systemId,
            @RequestParam(required = false) Long envId,
            @RequestParam(required = false) String status) {
        return monitoringService.listDatabases(systemId, envId, status);
    }

    @GetMapping("/databases/{datasourceId}/trend")
    @RequirePermission("sys:monitor:query")
    public List<MonitoringDtos.TrendPoint> databaseTrend(
            @PathVariable Long datasourceId,
            @RequestParam(defaultValue = "24h") String range) {
        return monitoringService.databaseTrend(datasourceId, range);
    }

    @GetMapping("/databases/{datasourceId}/slow-sql")
    @RequirePermission("sys:monitor:query")
    public List<MonitoringDtos.SlowSqlItem> slowSql(
            @PathVariable Long datasourceId,
            @RequestParam(defaultValue = "24h") String range,
            @RequestParam(defaultValue = "20") int limit) {
        return monitoringService.slowSql(datasourceId, range, limit);
    }

    @GetMapping("/thresholds")
    @RequirePermission("sys:monitor:query")
    public MonitoringDtos.ThresholdConfig thresholds(
            @RequestParam String targetType,
            @RequestParam(required = false) Long targetId) {
        MonitorThresholdService.ConfigView config = thresholdService.getConfig(targetType, targetId);
        return new MonitoringDtos.ThresholdConfig(
                config.targetType(), config.targetId(), config.enabled(),
                config.thresholds(), config.enabledMetrics());
    }

    @PutMapping("/thresholds")
    @RequirePermission("sys:monitor:config")
    public MonitoringDtos.ThresholdConfig updateThresholds(
            @RequestBody MonitoringDtos.ThresholdUpdateRequest request) {
        MonitorThresholdService.ConfigView config = thresholdService.saveConfig(
                request.targetType(), request.targetId(),
                request.enabled() == null || request.enabled(),
                request.thresholds(), request.enabledMetrics());
        return new MonitoringDtos.ThresholdConfig(
                config.targetType(), config.targetId(), config.enabled(),
                config.thresholds(), config.enabledMetrics());
    }

    @PostMapping("/collect/{targetType}/{targetId}")
    @RequirePermission("sys:monitor:collect")
    public MonitoringDtos.CollectResult collect(
            @PathVariable String targetType,
            @PathVariable Long targetId) {
        boolean accepted = monitoringService.collectAsync(targetType, targetId);
        return new MonitoringDtos.CollectResult(accepted, accepted ? "采集任务已提交" : "目标不可采集");
    }
}
