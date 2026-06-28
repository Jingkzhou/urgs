package com.example.urgs_api.monitoring.service;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

@Component
public class SystemMonitoringScheduler {

    private final SystemMonitoringService monitoringService;

    public SystemMonitoringScheduler(SystemMonitoringService monitoringService) {
        this.monitoringService = monitoringService;
    }

    @Scheduled(fixedDelayString = "${monitoring.collect-interval-ms:60000}")
    public void collectMetrics() {
        monitoringService.collectAllServers();
        monitoringService.collectAllDatabases();
    }

    @Scheduled(fixedDelayString = "${monitoring.slow-sql-interval-ms:300000}")
    public void collectSlowSql() {
        monitoringService.collectAllSlowSql();
    }

    @Scheduled(cron = "${monitoring.cleanup-cron:0 15 2 * * ?}")
    public void cleanupHistory() {
        monitoringService.cleanupExpiredSamples();
    }
}
