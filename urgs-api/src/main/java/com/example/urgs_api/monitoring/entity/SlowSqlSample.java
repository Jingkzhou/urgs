package com.example.urgs_api.monitoring.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@Entity
@Table(name = "sys_monitor_slow_sql_sample",
        indexes = @Index(name = "idx_monitor_slow_sql_datasource_time", columnList = "datasource_id,collected_at"))
public class SlowSqlSample {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "datasource_id", nullable = false)
    private Long datasourceId;

    @Column(name = "collected_at", nullable = false)
    private LocalDateTime collectedAt;

    @Column(nullable = false, length = 128)
    private String digest;

    @Lob
    @Column(name = "digest_text", nullable = false)
    private String digestText;

    @Column(nullable = false)
    private Long executions;

    @Column(name = "avg_latency_ms")
    private Double avgLatencyMs;

    @Column(name = "total_latency_ms")
    private Double totalLatencyMs;

    @Column(name = "rows_examined")
    private Long rowsExamined;

    @Column(name = "rows_sent")
    private Long rowsSent;
}
