package com.example.urgs_api.monitoring.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "sys_monitor_db_sample",
        indexes = @Index(name = "idx_monitor_db_datasource_time", columnList = "datasource_id,collected_at"))
public class DatabaseMetricSample {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "datasource_id", nullable = false)
    private Long datasourceId;

    @Column(name = "collected_at", nullable = false)
    private LocalDateTime collectedAt;

    @Column(name = "collection_state", nullable = false, length = 20)
    private String collectionState;

    @Column(nullable = false, length = 20)
    private String severity;

    @Column(length = 100)
    private String version;

    @Column(name = "latency_ms")
    private Long latencyMs;

    @Column(name = "threads_connected")
    private Long threadsConnected;

    @Column(name = "max_connections")
    private Long maxConnections;

    @Column(name = "threads_running")
    private Long threadsRunning;

    private Double qps;

    private Double tps;

    @Column(name = "slow_queries")
    private Long slowQueries;

    @Column(name = "slow_sql_avg_latency_ms")
    private Double slowSqlAvgLatencyMs;

    @Column(name = "buffer_pool_hit_percent")
    private Double bufferPoolHitPercent;

    @Column(name = "row_lock_waits")
    private Long rowLockWaits;

    @Column(name = "uptime_seconds")
    private Long uptimeSeconds;

    @Column(name = "capabilities_json", columnDefinition = "json")
    private String capabilitiesJson;

    @Column(name = "error_message", length = 500)
    private String errorMessage;
}
