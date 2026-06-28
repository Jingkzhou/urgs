package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.monitoring.entity.DatabaseMetricSample;
import com.example.urgs_api.monitoring.entity.MonitorTargetConfig;
import com.example.urgs_api.monitoring.entity.ServerMetricSample;
import com.example.urgs_api.monitoring.repository.MonitorTargetConfigRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

@Service
public class MonitorThresholdService {

    public static final String SERVER = "SERVER";
    public static final String DATABASE = "DATABASE";
    private static final long GLOBAL_TARGET_ID = 0L;
    private static final List<String> SERVER_METRICS = List.of("CPU", "MEMORY", "DISK", "LOAD", "NETWORK", "UPTIME");
    private static final Set<String> SERVER_METRIC_KEYS = Set.copyOf(SERVER_METRICS);
    private static final Set<String> SERVER_KEYS = Set.of(
            "cpuWarning", "cpuCritical", "memoryWarning", "memoryCritical", "diskWarning", "diskCritical");
    private static final Set<String> DATABASE_KEYS = Set.of(
            "connectionWarning", "connectionCritical", "latencyWarning", "latencyCritical",
            "slowSqlWarning", "slowSqlCritical", "lockWaitWarning", "lockWaitCritical");

    private final MonitorTargetConfigRepository repository;
    private final ObjectMapper objectMapper;

    public MonitorThresholdService(MonitorTargetConfigRepository repository, ObjectMapper objectMapper) {
        this.repository = repository;
        this.objectMapper = objectMapper;
    }

    public ConfigView getConfig(String targetType, Long targetId) {
        String type = normalizeType(targetType);
        long id = targetId == null ? GLOBAL_TARGET_ID : targetId;
        MonitorTargetConfig global = repository.findByTargetTypeAndTargetId(type, GLOBAL_TARGET_ID)
                .orElseGet(() -> defaultConfig(type, GLOBAL_TARGET_ID));
        Map<String, Double> thresholds = new LinkedHashMap<>(readThresholds(global.getThresholdsJson()));
        List<String> enabledMetrics = SERVER.equals(type)
                ? readEnabledMetrics(global.getThresholdsJson(), SERVER_METRICS)
                : List.of();
        boolean enabled = Boolean.TRUE.equals(global.getEnabled());
        if (id != GLOBAL_TARGET_ID) {
            MonitorTargetConfig override = repository.findByTargetTypeAndTargetId(type, id).orElse(null);
            if (override != null) {
                thresholds.putAll(readThresholds(override.getThresholdsJson()));
                if (SERVER.equals(type)) {
                    enabledMetrics = readEnabledMetrics(override.getThresholdsJson(), enabledMetrics);
                }
                enabled = Boolean.TRUE.equals(override.getEnabled());
            } else if (SERVER.equals(type)) {
                enabled = false;
            }
        }
        return new ConfigView(type, id, enabled, thresholds, enabledMetrics);
    }

    @Transactional
    public ConfigView saveConfig(String targetType, Long targetId, boolean enabled,
                                 Map<String, Double> thresholds) {
        return saveConfig(targetType, targetId, enabled, thresholds, null);
    }

    @Transactional
    public ConfigView saveConfig(String targetType, Long targetId, boolean enabled,
                                 Map<String, Double> thresholds, List<String> enabledMetrics) {
        String type = normalizeType(targetType);
        long id = targetId == null ? GLOBAL_TARGET_ID : targetId;
        if (id < GLOBAL_TARGET_ID) {
            throw new IllegalArgumentException("targetId 不能为负数");
        }
        validateThresholds(type, thresholds);
        ConfigView current = getConfig(type, id);
        List<String> metricsToSave = List.of();
        if (SERVER.equals(type)) {
            metricsToSave = enabledMetrics == null
                    ? current.enabledMetrics()
                    : normalizeEnabledMetrics(enabledMetrics);
        }
        MonitorTargetConfig config = repository.findByTargetTypeAndTargetId(type, id)
                .orElseGet(() -> defaultConfig(type, id));
        config.setEnabled(enabled);
        try {
            Map<String, Object> payload = new LinkedHashMap<>();
            payload.putAll(thresholds == null ? current.thresholds() : thresholds);
            if (SERVER.equals(type)) {
                payload.put("enabledMetrics", metricsToSave);
            }
            config.setThresholdsJson(objectMapper.writeValueAsString(payload));
        } catch (Exception e) {
            throw new IllegalArgumentException("阈值配置格式无效");
        }
        repository.save(config);
        return getConfig(type, id);
    }

    public String evaluateServer(ServerMetricSample sample, Map<String, Double> thresholds) {
        return evaluateServer(sample, thresholds, SERVER_METRICS);
    }

    public String evaluateServer(ServerMetricSample sample, Map<String, Double> thresholds, List<String> enabledMetrics) {
        List<String> metrics = normalizeEnabledMetrics(enabledMetrics);
        boolean critical = (metrics.contains("CPU") && exceeds(sample.getCpuPercent(), thresholds, "cpuCritical"))
                || (metrics.contains("MEMORY") && exceeds(sample.getMemoryPercent(), thresholds, "memoryCritical"))
                || (metrics.contains("DISK") && exceeds(sample.getDiskPercent(), thresholds, "diskCritical"));
        if (critical) return "CRITICAL";
        boolean warning = (metrics.contains("CPU") && exceeds(sample.getCpuPercent(), thresholds, "cpuWarning"))
                || (metrics.contains("MEMORY") && exceeds(sample.getMemoryPercent(), thresholds, "memoryWarning"))
                || (metrics.contains("DISK") && exceeds(sample.getDiskPercent(), thresholds, "diskWarning"));
        return warning ? "WARNING" : "NORMAL";
    }

    public String evaluateDatabase(DatabaseMetricSample sample, Map<String, Double> thresholds) {
        double connectionUsage = sample.getMaxConnections() == null || sample.getMaxConnections() <= 0
                ? 0 : sample.getThreadsConnected() * 100d / sample.getMaxConnections();
        boolean critical = exceeds(connectionUsage, thresholds, "connectionCritical")
                || exceeds(sample.getLatencyMs(), thresholds, "latencyCritical")
                || exceeds(sample.getSlowSqlAvgLatencyMs(), thresholds, "slowSqlCritical")
                || exceeds(sample.getRowLockWaits(), thresholds, "lockWaitCritical");
        if (critical) return "CRITICAL";
        boolean warning = exceeds(connectionUsage, thresholds, "connectionWarning")
                || exceeds(sample.getLatencyMs(), thresholds, "latencyWarning")
                || exceeds(sample.getSlowSqlAvgLatencyMs(), thresholds, "slowSqlWarning")
                || exceeds(sample.getRowLockWaits(), thresholds, "lockWaitWarning");
        return warning ? "WARNING" : "NORMAL";
    }

    private boolean exceeds(Number value, Map<String, Double> thresholds, String key) {
        return value != null && thresholds.get(key) != null && value.doubleValue() >= thresholds.get(key);
    }

    private MonitorTargetConfig defaultConfig(String type, long targetId) {
        MonitorTargetConfig config = new MonitorTargetConfig();
        config.setTargetType(type);
        config.setTargetId(targetId);
        config.setEnabled(true);
        try {
            config.setThresholdsJson(objectMapper.writeValueAsString(defaultThresholds(type)));
        } catch (Exception ignored) {
            config.setThresholdsJson("{}");
        }
        return config;
    }

    private Map<String, Double> readThresholds(String json) {
        if (json == null || json.isBlank()) return Map.of();
        try {
            Map<String, Object> raw = objectMapper.readValue(json, new TypeReference<>() {});
            Map<String, Double> thresholds = new LinkedHashMap<>();
            raw.forEach((key, value) -> {
                if (value instanceof Number number) {
                    thresholds.put(key, number.doubleValue());
                }
            });
            return thresholds;
        } catch (Exception e) {
            return Map.of();
        }
    }

    private List<String> readEnabledMetrics(String json, List<String> fallback) {
        if (json == null || json.isBlank()) return fallback;
        try {
            Map<String, Object> raw = objectMapper.readValue(json, new TypeReference<>() {});
            Object value = raw.get("enabledMetrics");
            if (!(value instanceof List<?> values)) {
                return fallback;
            }
            return normalizeEnabledMetrics(values.stream().map(String::valueOf).toList());
        } catch (Exception e) {
            return fallback;
        }
    }

    private Map<String, Double> defaultThresholds(String type) {
        if (SERVER.equals(type)) {
            return Map.of(
                    "cpuWarning", 80d, "cpuCritical", 90d,
                    "memoryWarning", 80d, "memoryCritical", 90d,
                    "diskWarning", 80d, "diskCritical", 90d
            );
        }
        return Map.of(
                "connectionWarning", 70d, "connectionCritical", 90d,
                "latencyWarning", 200d, "latencyCritical", 1000d,
                "slowSqlWarning", 1000d, "slowSqlCritical", 3000d,
                "lockWaitWarning", 1d, "lockWaitCritical", 5d
        );
    }

    private void validateThresholds(String type, Map<String, Double> thresholds) {
        if (thresholds == null) return;
        Set<String> allowedKeys = SERVER.equals(type) ? SERVER_KEYS : DATABASE_KEYS;
        thresholds.forEach((key, value) -> {
            if (!allowedKeys.contains(key) || value == null || value < 0 || !Double.isFinite(value)) {
                throw new IllegalArgumentException("阈值必须是非负有限数值");
            }
            if ((key.startsWith("cpu") || key.startsWith("memory")
                    || key.startsWith("disk") || key.startsWith("connection")) && value > 100) {
                throw new IllegalArgumentException("百分比阈值不能超过100");
            }
        });
        validatePair(thresholds, "cpuWarning", "cpuCritical");
        validatePair(thresholds, "memoryWarning", "memoryCritical");
        validatePair(thresholds, "diskWarning", "diskCritical");
        validatePair(thresholds, "connectionWarning", "connectionCritical");
        validatePair(thresholds, "latencyWarning", "latencyCritical");
        validatePair(thresholds, "slowSqlWarning", "slowSqlCritical");
        validatePair(thresholds, "lockWaitWarning", "lockWaitCritical");
    }

    private List<String> normalizeEnabledMetrics(List<String> enabledMetrics) {
        if (enabledMetrics == null) return SERVER_METRICS;
        List<String> metrics = new ArrayList<>();
        for (String item : enabledMetrics) {
            String metric = item == null ? "" : item.trim().toUpperCase();
            if (!SERVER_METRIC_KEYS.contains(metric)) {
                throw new IllegalArgumentException("服务器监控项无效");
            }
            if (!metrics.contains(metric)) {
                metrics.add(metric);
            }
        }
        if (metrics.isEmpty()) {
            throw new IllegalArgumentException("至少选择一个服务器监控项");
        }
        return metrics;
    }

    private void validatePair(Map<String, Double> thresholds, String warningKey, String criticalKey) {
        Double warning = thresholds.get(warningKey);
        Double critical = thresholds.get(criticalKey);
        if (warning != null && critical != null && warning > critical) {
            throw new IllegalArgumentException("预警阈值不能高于严重阈值");
        }
    }

    private String normalizeType(String targetType) {
        String type = targetType == null ? "" : targetType.trim().toUpperCase();
        if (!SERVER.equals(type) && !DATABASE.equals(type)) {
            throw new IllegalArgumentException("targetType 仅支持 SERVER 或 DATABASE");
        }
        return type;
    }

    public record ConfigView(String targetType, Long targetId, boolean enabled,
                             Map<String, Double> thresholds, List<String> enabledMetrics) {}
}
