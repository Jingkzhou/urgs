package com.example.urgs_api.monitoring.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "sys_monitor_server_sample",
        indexes = @Index(name = "idx_monitor_server_asset_time", columnList = "asset_id,collected_at"))
public class ServerMetricSample {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "asset_id", nullable = false)
    private Long assetId;

    @Column(name = "collected_at", nullable = false)
    private LocalDateTime collectedAt;

    @Column(name = "collection_state", nullable = false, length = 20)
    private String collectionState;

    @Column(nullable = false, length = 20)
    private String severity;

    @Column(name = "cpu_percent")
    private Double cpuPercent;

    @Column(name = "load_one")
    private Double loadOne;

    @Column(name = "memory_total_bytes")
    private Long memoryTotalBytes;

    @Column(name = "memory_used_bytes")
    private Long memoryUsedBytes;

    @Column(name = "memory_percent")
    private Double memoryPercent;

    @Column(name = "disk_total_bytes")
    private Long diskTotalBytes;

    @Column(name = "disk_used_bytes")
    private Long diskUsedBytes;

    @Column(name = "disk_percent")
    private Double diskPercent;

    @Column(name = "disk_details_json", columnDefinition = "json")
    private String diskDetailsJson;

    @Column(name = "network_rx_bps")
    private Long networkRxBps;

    @Column(name = "network_tx_bps")
    private Long networkTxBps;

    @Column(name = "uptime_seconds")
    private Long uptimeSeconds;

    @Column(name = "error_message", length = 500)
    private String errorMessage;
}
