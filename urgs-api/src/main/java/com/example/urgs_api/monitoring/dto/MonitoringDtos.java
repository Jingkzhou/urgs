package com.example.urgs_api.monitoring.dto;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class MonitoringDtos {

    private MonitoringDtos() {}

    public record Overview(int total, int normal, int warning, int critical, int unavailable,
                           LocalDateTime latestCollectedAt) {}

    public record ServerSummary(
            Long assetId,
            String hostname,
            String internalIp,
            String osType,
            Long systemId,
            Long envId,
            String envType,
            String assetStatus,
            boolean monitorEnabled,
            String collectionState,
            String severity,
            Double cpuPercent,
            Double memoryPercent,
            Double diskPercent,
            Double loadOne,
            Long networkRxBps,
            Long networkTxBps,
            Long uptimeSeconds,
            LocalDateTime collectedAt,
            String errorMessage,
            List<DiskUsage> disks,
            List<String> enabledMetrics
    ) {}

    public record DatabaseSummary(
            Long datasourceId,
            String name,
            String host,
            Integer port,
            String databaseName,
            String version,
            String collectionState,
            String severity,
            Long latencyMs,
            Long threadsConnected,
            Long maxConnections,
            Long threadsRunning,
            Double connectionPercent,
            Double qps,
            Double tps,
            Long slowQueries,
            Double slowSqlAvgLatencyMs,
            Double bufferPoolHitPercent,
            Long rowLockWaits,
            Long uptimeSeconds,
            LocalDateTime collectedAt,
            boolean slowSqlAvailable,
            String errorMessage
    ) {}

    public record DiskUsage(String filesystem, String mountPoint, long totalBytes, long usedBytes,
                            double usedPercent) {}

    public record TrendPoint(
            LocalDateTime time,
            Double cpuPercent,
            Double memoryPercent,
            Double diskPercent,
            Double loadOne,
            Long networkRxBps,
            Long networkTxBps,
            Long latencyMs,
            Double connectionPercent,
            Double qps,
            Double tps,
            Long slowQueries,
            Double bufferPoolHitPercent,
            Long rowLockWaits
    ) {}

    public record SlowSqlItem(
            String digest,
            String digestText,
            Long executions,
            Double avgLatencyMs,
            Double totalLatencyMs,
            Long rowsExamined,
            Long rowsSent,
            LocalDateTime collectedAt
    ) {}

    public record ThresholdConfig(String targetType, Long targetId, boolean enabled,
                                  Map<String, Double> thresholds,
                                  List<String> enabledMetrics) {}

    public record ThresholdUpdateRequest(String targetType, Long targetId, Boolean enabled,
                                         Map<String, Double> thresholds,
                                         List<String> enabledMetrics) {}

    public record CollectResult(boolean accepted, String message) {}
}
