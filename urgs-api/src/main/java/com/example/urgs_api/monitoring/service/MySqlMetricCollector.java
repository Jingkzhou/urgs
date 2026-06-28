package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.datasource.service.DynamicDataSourceService;
import com.example.urgs_api.monitoring.entity.DatabaseMetricSample;
import com.example.urgs_api.monitoring.entity.SlowSqlSample;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class MySqlMetricCollector {

    private static final List<String> STATUS_NAMES = List.of(
            "Threads_connected", "Threads_running", "Questions", "Com_commit", "Com_rollback",
            "Slow_queries", "Innodb_buffer_pool_reads", "Innodb_buffer_pool_read_requests",
            "Innodb_row_lock_current_waits", "Uptime"
    );

    private final DynamicDataSourceService dynamicDataSourceService;
    private final ObjectMapper objectMapper;
    private final Map<Long, CounterSnapshot> previousCounters = new ConcurrentHashMap<>();

    public MySqlMetricCollector(DynamicDataSourceService dynamicDataSourceService, ObjectMapper objectMapper) {
        this.dynamicDataSourceService = dynamicDataSourceService;
        this.objectMapper = objectMapper;
    }

    public DatabaseMetricSample collect(Long datasourceId) {
        LocalDateTime collectedAt = LocalDateTime.now();
        DatabaseMetricSample sample = baseSample(datasourceId, collectedAt, "LIVE");
        try {
            JdbcTemplate jdbc = monitoringTemplate(datasourceId);
            long startedAt = System.nanoTime();
            String version = jdbc.queryForObject("SELECT VERSION()", String.class);
            sample.setLatencyMs(Math.max(0, (System.nanoTime() - startedAt) / 1_000_000));
            sample.setVersion(version);

            Map<String, Long> status = readStatus(jdbc);
            long maxConnections = number(jdbc.queryForObject(
                    "SELECT @@GLOBAL.max_connections", Number.class));
            CounterSnapshot current = CounterSnapshot.from(status);
            CounterSnapshot previous = previousCounters.put(datasourceId, current);
            long elapsed = previous == null ? 0 : Math.max(1, current.uptime() - previous.uptime());

            sample.setThreadsConnected(status.getOrDefault("Threads_connected", 0L));
            sample.setThreadsRunning(status.getOrDefault("Threads_running", 0L));
            sample.setMaxConnections(maxConnections);
            sample.setQps(previous == null ? 0 : delta(current.questions(), previous.questions()) / (double) elapsed);
            sample.setTps(previous == null ? 0
                    : (delta(current.comCommit(), previous.comCommit())
                    + delta(current.comRollback(), previous.comRollback())) / (double) elapsed);
            sample.setSlowQueries(previous == null ? 0 : delta(current.slowQueries(), previous.slowQueries()));
            sample.setRowLockWaits(status.getOrDefault("Innodb_row_lock_current_waits", 0L));
            sample.setUptimeSeconds(current.uptime());

            long reads = status.getOrDefault("Innodb_buffer_pool_reads", 0L);
            long requests = status.getOrDefault("Innodb_buffer_pool_read_requests", 0L);
            sample.setBufferPoolHitPercent(requests <= 0 ? 100d
                    : Math.max(0, Math.min(100, (1d - reads / (double) requests) * 100d)));
            sample.setCapabilitiesJson(objectMapper.writeValueAsString(
                    Map.of("status", true, "performanceSchema", hasPerformanceSchema(jdbc))));
            return sample;
        } catch (Exception e) {
            sample.setCollectionState("UNAVAILABLE");
            sample.setSeverity("CRITICAL");
            sample.setErrorMessage(sanitize(e.getMessage(), "MySQL指标采集失败"));
            return sample;
        }
    }

    public List<SlowSqlSample> collectSlowSql(Long datasourceId) {
        JdbcTemplate jdbc = monitoringTemplate(datasourceId);
        String sql = """
                SELECT DIGEST, LEFT(DIGEST_TEXT, 4000) AS DIGEST_TEXT, COUNT_STAR,
                       AVG_TIMER_WAIT / 1000000000 AS AVG_LATENCY_MS,
                       SUM_TIMER_WAIT / 1000000000 AS TOTAL_LATENCY_MS,
                       SUM_ROWS_EXAMINED, SUM_ROWS_SENT
                FROM performance_schema.events_statements_summary_by_digest
                WHERE DIGEST IS NOT NULL AND DIGEST_TEXT IS NOT NULL
                  AND SCHEMA_NAME = DATABASE()
                ORDER BY SUM_TIMER_WAIT DESC
                LIMIT 20
                """;
        LocalDateTime collectedAt = LocalDateTime.now();
        return jdbc.query(sql, (rs, rowNum) -> {
            SlowSqlSample sample = new SlowSqlSample();
            sample.setDatasourceId(datasourceId);
            sample.setCollectedAt(collectedAt);
            sample.setDigest(rs.getString("DIGEST"));
            sample.setDigestText(normalizeDigestText(rs.getString("DIGEST_TEXT")));
            sample.setExecutions(rs.getLong("COUNT_STAR"));
            sample.setAvgLatencyMs(rs.getDouble("AVG_LATENCY_MS"));
            sample.setTotalLatencyMs(rs.getDouble("TOTAL_LATENCY_MS"));
            sample.setRowsExamined(rs.getLong("SUM_ROWS_EXAMINED"));
            sample.setRowsSent(rs.getLong("SUM_ROWS_SENT"));
            return sample;
        });
    }

    private Map<String, Long> readStatus(JdbcTemplate jdbc) {
        String names = STATUS_NAMES.stream().map(name -> "'" + name + "'").collect(java.util.stream.Collectors.joining(","));
        String sql = "SHOW GLOBAL STATUS WHERE Variable_name IN (" + names + ")";
        Map<String, Long> values = new HashMap<>();
        jdbc.query(sql, rs -> {
            values.put(rs.getString("Variable_name"), parseLong(rs.getString("Value")));
        });
        return values;
    }

    private JdbcTemplate monitoringTemplate(Long datasourceId) {
        JdbcTemplate shared = dynamicDataSourceService.getJdbcTemplate(datasourceId);
        JdbcTemplate monitoring = new JdbcTemplate(Objects.requireNonNull(shared.getDataSource()));
        monitoring.setQueryTimeout(5);
        return monitoring;
    }

    private boolean hasPerformanceSchema(JdbcTemplate jdbc) {
        try {
            Number count = jdbc.queryForObject("""
                    SELECT COUNT(*) FROM information_schema.tables
                    WHERE table_schema = 'performance_schema'
                      AND table_name = 'events_statements_summary_by_digest'
                    """, Number.class);
            return count != null && count.longValue() > 0;
        } catch (Exception ignored) {
            return false;
        }
    }

    private DatabaseMetricSample baseSample(Long datasourceId, LocalDateTime collectedAt, String state) {
        DatabaseMetricSample sample = new DatabaseMetricSample();
        sample.setDatasourceId(datasourceId);
        sample.setCollectedAt(collectedAt);
        sample.setCollectionState(state);
        sample.setSeverity("NORMAL");
        return sample;
    }

    private long number(Number value) {
        return value == null ? 0 : value.longValue();
    }

    private long parseLong(String value) {
        try {
            return Long.parseLong(value);
        } catch (Exception ignored) {
            return 0;
        }
    }

    private long delta(long current, long previous) {
        return current >= previous ? current - previous : 0;
    }

    private String normalizeDigestText(String text) {
        if (text == null) return "";
        return text.replaceAll("\\s+", " ").trim();
    }

    private String sanitize(String value, String fallback) {
        if (value == null || value.isBlank()) return fallback;
        String sanitized = value.replaceAll("[\\r\\n\\t]+", " ")
                .replaceAll("(?i)(password|pwd)=[^\\s;&]+", "$1=******")
                .trim();
        return sanitized.length() > 500 ? sanitized.substring(0, 500) : sanitized;
    }

    private record CounterSnapshot(long questions, long comCommit, long comRollback,
                                   long slowQueries, long uptime) {
        static CounterSnapshot from(Map<String, Long> status) {
            return new CounterSnapshot(
                    status.getOrDefault("Questions", 0L),
                    status.getOrDefault("Com_commit", 0L),
                    status.getOrDefault("Com_rollback", 0L),
                    status.getOrDefault("Slow_queries", 0L),
                    status.getOrDefault("Uptime", 0L)
            );
        }
    }
}
