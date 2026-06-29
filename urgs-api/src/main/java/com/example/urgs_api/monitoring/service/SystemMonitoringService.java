package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.service.DataSourceService;
import com.example.urgs_api.monitoring.dto.MonitoringDtos;
import com.example.urgs_api.monitoring.entity.DatabaseMetricSample;
import com.example.urgs_api.monitoring.entity.ServerMetricSample;
import com.example.urgs_api.monitoring.entity.SlowSqlSample;
import com.example.urgs_api.monitoring.repository.DatabaseMetricSampleRepository;
import com.example.urgs_api.monitoring.repository.ServerMetricSampleRepository;
import com.example.urgs_api.monitoring.repository.SlowSqlSampleRepository;
import com.example.urgs_api.ops.entity.InfrastructureAsset;
import com.example.urgs_api.ops.entity.InfrastructureUser;
import com.example.urgs_api.ops.repository.InfrastructureAssetRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.*;
import java.time.temporal.ChronoUnit;
import java.util.*;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.Executor;
import java.util.stream.Collectors;

@Service
public class SystemMonitoringService {

    private static final int RETENTION_DAYS = 7;

    private final InfrastructureAssetRepository assetRepository;
    private final DataSourceService dataSourceService;
    private final ServerMetricSampleRepository serverSampleRepository;
    private final DatabaseMetricSampleRepository databaseSampleRepository;
    private final SlowSqlSampleRepository slowSqlSampleRepository;
    private final SshServerMetricCollector serverCollector;
    private final MySqlMetricCollector mysqlCollector;
    private final MonitorThresholdService thresholdService;
    private final ObjectMapper objectMapper;
    private final Executor executor;
    private final Duration staleAfter;
    private final Set<String> collecting = ConcurrentHashMap.newKeySet();

    public SystemMonitoringService(
            InfrastructureAssetRepository assetRepository,
            DataSourceService dataSourceService,
            ServerMetricSampleRepository serverSampleRepository,
            DatabaseMetricSampleRepository databaseSampleRepository,
            SlowSqlSampleRepository slowSqlSampleRepository,
            SshServerMetricCollector serverCollector,
            MySqlMetricCollector mysqlCollector,
            MonitorThresholdService thresholdService,
            ObjectMapper objectMapper,
            @Qualifier("monitoringTaskExecutor") Executor executor,
            @Value("${monitoring.collect-interval-ms:60000}") long collectIntervalMs) {
        this.assetRepository = assetRepository;
        this.dataSourceService = dataSourceService;
        this.serverSampleRepository = serverSampleRepository;
        this.databaseSampleRepository = databaseSampleRepository;
        this.slowSqlSampleRepository = slowSqlSampleRepository;
        this.serverCollector = serverCollector;
        this.mysqlCollector = mysqlCollector;
        this.thresholdService = thresholdService;
        this.objectMapper = objectMapper;
        this.executor = executor;
        this.staleAfter = Duration.ofMillis(Math.max(130_000L, collectIntervalMs * 2 + 10_000L));
    }

    public List<MonitoringDtos.ServerSummary> listServers(Long systemId, Long envId, String status, boolean includeDisabled) {
        return assetRepository.findAll().stream()
                .filter(asset -> systemId == null || Objects.equals(systemId, asset.getAppSystemId()))
                .filter(asset -> envId == null || Objects.equals(envId, asset.getEnvId()))
                .map(this::toServerSummary)
                .filter(item -> includeDisabled || item.monitorEnabled())
                .filter(item -> status == null || status.isBlank()
                        || status.equalsIgnoreCase(item.severity())
                        || status.equalsIgnoreCase(item.collectionState()))
                .sorted(Comparator.comparingInt((MonitoringDtos.ServerSummary item) -> severityOrder(item.severity()))
                        .reversed()
                        .thenComparing(MonitoringDtos.ServerSummary::hostname,
                                Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)))
                .toList();
    }

    public List<MonitoringDtos.DatabaseSummary> listDatabases(Long systemId, Long envId, String status) {
        return mysqlDataSources().stream()
                .filter(datasource -> systemId == null || Objects.equals(systemId, datasource.getAppSystemId()))
                .filter(datasource -> envId == null || Objects.equals(envId, datasource.getEnvId()))
                .map(this::toDatabaseSummary)
                .filter(item -> status == null || status.isBlank()
                        || status.equalsIgnoreCase(item.severity())
                        || status.equalsIgnoreCase(item.collectionState()))
                .sorted(Comparator.comparingInt((MonitoringDtos.DatabaseSummary item) -> severityOrder(item.severity()))
                        .reversed()
                        .thenComparing(MonitoringDtos.DatabaseSummary::name,
                                Comparator.nullsLast(String.CASE_INSENSITIVE_ORDER)))
                .toList();
    }

    public MonitoringDtos.Overview overview(String targetType, Long systemId, Long envId, String status) {
        List<StatusView> statuses = new ArrayList<>();
        if (targetType == null || targetType.isBlank() || MonitorThresholdService.SERVER.equalsIgnoreCase(targetType)) {
            listServers(systemId, envId, status, false).forEach(item ->
                    statuses.add(new StatusView(item.severity(), item.collectionState(), item.collectedAt())));
        }
        if (targetType == null || targetType.isBlank() || MonitorThresholdService.DATABASE.equalsIgnoreCase(targetType)) {
            listDatabases(systemId, envId, status).forEach(item ->
                    statuses.add(new StatusView(item.severity(), item.collectionState(), item.collectedAt())));
        }
        int normal = 0;
        int warning = 0;
        int critical = 0;
        int unavailable = 0;
        LocalDateTime latest = null;
        for (StatusView item : statuses) {
            if (Set.of("UNAVAILABLE", "STALE", "UNSUPPORTED").contains(item.collectionState())) {
                unavailable++;
            } else if ("WARNING".equals(item.severity())) {
                warning++;
            } else if ("CRITICAL".equals(item.severity())) {
                critical++;
            } else if (!"PAUSED".equals(item.collectionState())) {
                normal++;
            }
            if (item.collectedAt() != null && (latest == null || item.collectedAt().isAfter(latest))) {
                latest = item.collectedAt();
            }
        }
        return new MonitoringDtos.Overview(statuses.size(), normal, warning, critical, unavailable, latest);
    }

    public List<MonitoringDtos.TrendPoint> serverTrend(Long assetId, String range) {
        RangeSpec spec = RangeSpec.parse(range);
        List<ServerMetricSample> samples = serverSampleRepository
                .findByAssetIdAndCollectedAtGreaterThanEqualOrderByCollectedAtAsc(
                        assetId, LocalDateTime.now().minus(spec.duration()));
        return aggregateServer(
                samples,
                spec.bucketMinutes(),
                thresholdService.getConfig(MonitorThresholdService.SERVER, assetId).enabledMetrics()
        );
    }

    public List<MonitoringDtos.TrendPoint> databaseTrend(Long datasourceId, String range) {
        RangeSpec spec = RangeSpec.parse(range);
        List<DatabaseMetricSample> samples = databaseSampleRepository
                .findByDatasourceIdAndCollectedAtGreaterThanEqualOrderByCollectedAtAsc(
                        datasourceId, LocalDateTime.now().minus(spec.duration()));
        return aggregateDatabase(samples, spec.bucketMinutes());
    }

    public List<MonitoringDtos.SlowSqlItem> slowSql(Long datasourceId, String range, int limit) {
        RangeSpec spec = RangeSpec.parse(range);
        int safeLimit = Math.max(1, Math.min(100, limit));
        Map<String, SlowSqlSample> latestByDigest = new HashMap<>();
        slowSqlSampleRepository
                .findByDatasourceIdAndCollectedAtGreaterThanEqualOrderByTotalLatencyMsDesc(
                        datasourceId, LocalDateTime.now().minus(spec.duration()))
                .forEach(sample -> latestByDigest.merge(sample.getDigest(), sample,
                        (left, right) -> right.getCollectedAt().isAfter(left.getCollectedAt()) ? right : left));
        return latestByDigest.values().stream()
                .sorted(Comparator.comparing(SlowSqlSample::getTotalLatencyMs,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(safeLimit)
                .map(sample -> new MonitoringDtos.SlowSqlItem(
                        sample.getDigest(), sample.getDigestText(), sample.getExecutions(),
                        sample.getAvgLatencyMs(), sample.getTotalLatencyMs(),
                        sample.getRowsExamined(), sample.getRowsSent(), sample.getCollectedAt()))
                .toList();
    }

    public boolean collectAsync(String targetType, Long targetId) {
        if (targetId == null || targetId <= 0) return false;
        String type = targetType == null ? "" : targetType.trim().toUpperCase();
        if (MonitorThresholdService.SERVER.equals(type)) {
            InfrastructureAsset asset = assetRepository.findById(targetId).orElse(null);
            if (asset == null || !isCollectableServer(asset)) return false;
            executor.execute(() -> collectServer(asset));
            return true;
        }
        if (MonitorThresholdService.DATABASE.equals(type)) {
            DataSourceConfig datasource = mysqlDataSources().stream()
                    .filter(item -> Objects.equals(item.getId(), targetId)).findFirst().orElse(null);
            if (datasource == null || !isCollectableDatabase(datasource.getId())) return false;
            executor.execute(() -> collectDatabase(datasource.getId()));
            return true;
        }
        return false;
    }

    public void collectAllServers() {
        assetRepository.findAll().stream()
                .filter(this::isCollectableServer)
                .forEach(asset -> executor.execute(() -> collectServer(asset)));
    }

    public void collectAllDatabases() {
        mysqlDataSources().stream()
                .filter(datasource -> isCollectableDatabase(datasource.getId()))
                .forEach(datasource -> executor.execute(() -> collectDatabase(datasource.getId())));
    }

    public void collectAllSlowSql() {
        mysqlDataSources().stream()
                .filter(datasource -> isCollectableDatabase(datasource.getId()))
                .forEach(datasource -> executor.execute(() -> collectSlowSql(datasource.getId())));
    }

    @Transactional
    public void cleanupExpiredSamples() {
        LocalDateTime before = LocalDateTime.now().minusDays(RETENTION_DAYS);
        serverSampleRepository.deleteByCollectedAtBefore(before);
        databaseSampleRepository.deleteByCollectedAtBefore(before);
        slowSqlSampleRepository.deleteByCollectedAtBefore(before);
    }

    private void collectServer(InfrastructureAsset asset) {
        String key = "SERVER:" + asset.getId();
        if (!collecting.add(key)) return;
        try {
            MonitorThresholdService.ConfigView config =
                    thresholdService.getConfig(MonitorThresholdService.SERVER, asset.getId());
            if (!config.enabled()) return;
            InfrastructureUser credential = osCredential(asset);
            ServerMetricSample sample = serverCollector.collect(asset, credential);
            if ("LIVE".equals(sample.getCollectionState())) {
                applyServerMetricSelection(sample, config.enabledMetrics());
                sample.setSeverity(thresholdService.evaluateServer(sample, config.thresholds(), config.enabledMetrics()));
            }
            serverSampleRepository.save(sample);
        } finally {
            collecting.remove(key);
        }
    }

    private void collectDatabase(Long datasourceId) {
        String key = "DATABASE:" + datasourceId;
        if (!collecting.add(key)) return;
        try {
            MonitorThresholdService.ConfigView config =
                    thresholdService.getConfig(MonitorThresholdService.DATABASE, datasourceId);
            if (!config.enabled()) return;
            DatabaseMetricSample sample = mysqlCollector.collect(datasourceId);
            if ("LIVE".equals(sample.getCollectionState())) {
                databaseSampleRepository.findTopByDatasourceIdOrderByCollectedAtDesc(datasourceId)
                        .map(DatabaseMetricSample::getSlowSqlAvgLatencyMs)
                        .ifPresent(sample::setSlowSqlAvgLatencyMs);
                sample.setSeverity(thresholdService.evaluateDatabase(sample, config.thresholds()));
            }
            databaseSampleRepository.save(sample);
        } finally {
            collecting.remove(key);
        }
    }

    private void collectSlowSql(Long datasourceId) {
        String key = "SLOWSQL:" + datasourceId;
        if (!collecting.add(key)) return;
        try {
            MonitorThresholdService.ConfigView config =
                    thresholdService.getConfig(MonitorThresholdService.DATABASE, datasourceId);
            if (!config.enabled()) return;
            List<SlowSqlSample> samples = mysqlCollector.collectSlowSql(datasourceId);
            slowSqlSampleRepository.saveAll(samples);
            databaseSampleRepository.findTopByDatasourceIdOrderByCollectedAtDesc(datasourceId)
                    .ifPresent(sample -> {
                        sample.setSlowSqlAvgLatencyMs(samples.stream()
                                .map(SlowSqlSample::getAvgLatencyMs)
                                .filter(Objects::nonNull)
                                .max(Double::compareTo)
                                .orElse(0d));
                        sample.setSeverity(thresholdService.evaluateDatabase(sample, config.thresholds()));
                        databaseSampleRepository.save(sample);
                    });
        } catch (Exception ignored) {
            databaseSampleRepository.findTopByDatasourceIdOrderByCollectedAtDesc(datasourceId)
                    .ifPresent(sample -> {
                        sample.setCapabilitiesJson(withSlowSqlUnavailable(sample.getCapabilitiesJson()));
                        databaseSampleRepository.save(sample);
                    });
        } finally {
            collecting.remove(key);
        }
    }

    private MonitoringDtos.ServerSummary toServerSummary(InfrastructureAsset asset) {
        ServerMetricSample latest = serverSampleRepository.findTopByAssetIdOrderByCollectedAtDesc(asset.getId())
                .orElse(null);
        MonitorThresholdService.ConfigView config = thresholdService.getConfig(MonitorThresholdService.SERVER, asset.getId());
        boolean enabled = config.enabled();
        List<String> enabledMetrics = config.enabledMetrics();
        String state;
        String error = latest == null ? null : latest.getErrorMessage();
        if (!enabled) {
            state = "PAUSED";
            error = "监控已禁用";
        } else if ("maintenance".equalsIgnoreCase(asset.getStatus())) {
            state = "PAUSED";
        } else if ("offline".equalsIgnoreCase(asset.getStatus())) {
            state = "UNAVAILABLE";
            error = "资产已下线";
        } else if (isWindows(asset)) {
            state = "UNSUPPORTED";
            error = "首期暂不支持Windows服务器";
        } else if (osCredential(asset) == null) {
            state = "UNAVAILABLE";
            error = "缺少操作系统账号";
        } else if (latest == null) {
            state = "UNAVAILABLE";
            error = "尚未采集";
        } else if (Duration.between(latest.getCollectedAt(), LocalDateTime.now()).compareTo(staleAfter) > 0) {
            state = "STALE";
        } else {
            state = latest.getCollectionState();
        }
        String severity = latest == null ? "NORMAL" : latest.getSeverity();
        if ("PAUSED".equals(state)) severity = "NORMAL";
        if ("UNAVAILABLE".equals(state) && "active".equalsIgnoreCase(asset.getStatus())) severity = "CRITICAL";
        return new MonitoringDtos.ServerSummary(
                asset.getId(), asset.getHostname(), asset.getInternalIp(), asset.getOsType(),
                asset.getAppSystemId(), asset.getEnvId(), asset.getEnvType(), asset.getStatus(),
                enabled, state, severity,
                value(latest, ServerMetricSample::getCpuPercent, enabledMetrics, "CPU"),
                value(latest, ServerMetricSample::getMemoryPercent, enabledMetrics, "MEMORY"),
                value(latest, ServerMetricSample::getDiskPercent, enabledMetrics, "DISK"),
                value(latest, ServerMetricSample::getLoadOne, enabledMetrics, "LOAD"),
                serverMetricEnabled(enabledMetrics, "NETWORK") && latest != null ? latest.getNetworkRxBps() : null,
                serverMetricEnabled(enabledMetrics, "NETWORK") && latest != null ? latest.getNetworkTxBps() : null,
                serverMetricEnabled(enabledMetrics, "UPTIME") && latest != null ? latest.getUptimeSeconds() : null,
                latest == null ? null : latest.getCollectedAt(),
                error,
                serverMetricEnabled(enabledMetrics, "DISK")
                        ? parseDisks(latest == null ? null : latest.getDiskDetailsJson())
                        : List.of(),
                enabledMetrics
        );
    }

    private MonitoringDtos.DatabaseSummary toDatabaseSummary(DataSourceConfig datasource) {
        DatabaseMetricSample latest = databaseSampleRepository
                .findTopByDatasourceIdOrderByCollectedAtDesc(datasource.getId()).orElse(null);
        boolean enabled = thresholdService.getConfig(MonitorThresholdService.DATABASE, datasource.getId()).enabled();
        String state;
        String error = latest == null ? "尚未采集" : latest.getErrorMessage();
        if (!enabled) {
            state = "PAUSED";
            error = "监控已禁用";
        } else if (latest == null) state = "UNAVAILABLE";
        else if (Duration.between(latest.getCollectedAt(), LocalDateTime.now()).compareTo(staleAfter) > 0) {
            state = "STALE";
        } else state = latest.getCollectionState();
        String severity = latest == null ? "NORMAL" : latest.getSeverity();
        if ("PAUSED".equals(state)) severity = "NORMAL";
        if ("UNAVAILABLE".equals(state)) severity = "CRITICAL";
        long connected = latest == null || latest.getThreadsConnected() == null ? 0 : latest.getThreadsConnected();
        long max = latest == null || latest.getMaxConnections() == null ? 0 : latest.getMaxConnections();
        Map<String, Object> params = datasource.getConnectionParams() == null ? Map.of() : datasource.getConnectionParams();
        return new MonitoringDtos.DatabaseSummary(
                datasource.getId(), datasource.getName(),
                text(params, "host"), integer(params, "port"),
                firstText(params, "database", "dbName", "databaseName"),
                latest == null ? null : latest.getVersion(), state, severity,
                latest == null ? null : latest.getLatencyMs(),
                latest == null ? null : latest.getThreadsConnected(),
                latest == null ? null : latest.getMaxConnections(),
                latest == null ? null : latest.getThreadsRunning(),
                max <= 0 ? 0 : connected * 100d / max,
                latest == null ? null : latest.getQps(),
                latest == null ? null : latest.getTps(),
                latest == null ? null : latest.getSlowQueries(),
                latest == null ? null : latest.getSlowSqlAvgLatencyMs(),
                latest == null ? null : latest.getBufferPoolHitPercent(),
                latest == null ? null : latest.getRowLockWaits(),
                latest == null ? null : latest.getUptimeSeconds(),
                latest == null ? null : latest.getCollectedAt(),
                slowSqlAvailable(latest), error
        );
    }

    private List<DataSourceConfig> mysqlDataSources() {
        return dataSourceService.getAllConfigs().stream()
                .filter(item -> item.getStatus() == null || item.getStatus() == 1)
                .filter(item -> "mysql".equalsIgnoreCase(item.getTypeCode()))
                .toList();
    }

    private boolean isCollectableServer(InfrastructureAsset asset) {
        return asset.getId() != null
                && "active".equalsIgnoreCase(asset.getStatus())
                && !isWindows(asset)
                && osCredential(asset) != null
                && thresholdService.getConfig(MonitorThresholdService.SERVER, asset.getId()).enabled();
    }

    private boolean isCollectableDatabase(Long datasourceId) {
        return datasourceId != null
                && thresholdService.getConfig(MonitorThresholdService.DATABASE, datasourceId).enabled();
    }

    private boolean isWindows(InfrastructureAsset asset) {
        return asset.getOsType() != null && asset.getOsType().toLowerCase().contains("windows");
    }

    private InfrastructureUser osCredential(InfrastructureAsset asset) {
        if (asset.getUsers() == null) return null;
        return asset.getUsers().stream()
                .filter(user -> user.getUserType() == null || "os".equalsIgnoreCase(user.getUserType()))
                .findFirst().orElse(null);
    }

    private String withSlowSqlUnavailable(String capabilitiesJson) {
        try {
            Map<String, Object> capabilities = capabilitiesJson == null
                    ? new LinkedHashMap<>()
                    : objectMapper.readValue(capabilitiesJson, new TypeReference<>() {});
            capabilities.put("performanceSchema", false);
            return objectMapper.writeValueAsString(capabilities);
        } catch (Exception ignored) {
            return "{\"status\":true,\"performanceSchema\":false}";
        }
    }

    private boolean slowSqlAvailable(DatabaseMetricSample sample) {
        if (sample == null || sample.getCapabilitiesJson() == null) return false;
        try {
            Map<String, Object> value = objectMapper.readValue(sample.getCapabilitiesJson(), new TypeReference<>() {});
            return Boolean.TRUE.equals(value.get("performanceSchema"));
        } catch (Exception ignored) {
            return false;
        }
    }

    private List<MonitoringDtos.DiskUsage> parseDisks(String json) {
        if (json == null || json.isBlank()) return List.of();
        try {
            return objectMapper.readValue(json, new TypeReference<>() {});
        } catch (Exception ignored) {
            return List.of();
        }
    }

    private List<MonitoringDtos.TrendPoint> aggregateServer(List<ServerMetricSample> samples, int bucketMinutes,
                                                            List<String> enabledMetrics) {
        return samples.stream()
                .collect(Collectors.groupingBy(sample -> bucket(sample.getCollectedAt(), bucketMinutes),
                        TreeMap::new, Collectors.toList()))
                .entrySet().stream()
                .map(entry -> {
                    List<ServerMetricSample> values = entry.getValue();
                    return new MonitoringDtos.TrendPoint(
                            entry.getKey(),
                            serverMetricEnabled(enabledMetrics, "CPU")
                                    ? average(values, ServerMetricSample::getCpuPercent) : null,
                            serverMetricEnabled(enabledMetrics, "MEMORY")
                                    ? average(values, ServerMetricSample::getMemoryPercent) : null,
                            serverMetricEnabled(enabledMetrics, "DISK")
                                    ? average(values, ServerMetricSample::getDiskPercent) : null,
                            serverMetricEnabled(enabledMetrics, "LOAD")
                                    ? average(values, ServerMetricSample::getLoadOne) : null,
                            serverMetricEnabled(enabledMetrics, "NETWORK")
                                    ? averageLong(values, ServerMetricSample::getNetworkRxBps) : null,
                            serverMetricEnabled(enabledMetrics, "NETWORK")
                                    ? averageLong(values, ServerMetricSample::getNetworkTxBps) : null,
                            null, null, null, null, null, null, null
                    );
                }).toList();
    }

    private List<MonitoringDtos.TrendPoint> aggregateDatabase(List<DatabaseMetricSample> samples, int bucketMinutes) {
        return samples.stream()
                .collect(Collectors.groupingBy(sample -> bucket(sample.getCollectedAt(), bucketMinutes),
                        TreeMap::new, Collectors.toList()))
                .entrySet().stream()
                .map(entry -> {
                    List<DatabaseMetricSample> values = entry.getValue();
                    return new MonitoringDtos.TrendPoint(
                            entry.getKey(), null, null, null, null, null, null,
                            averageLong(values, DatabaseMetricSample::getLatencyMs),
                            average(values, sample -> {
                                Long max = sample.getMaxConnections();
                                Long connected = sample.getThreadsConnected();
                                return max == null || max <= 0 || connected == null ? null : connected * 100d / max;
                            }),
                            average(values, DatabaseMetricSample::getQps),
                            average(values, DatabaseMetricSample::getTps),
                            averageLong(values, DatabaseMetricSample::getSlowQueries),
                            average(values, DatabaseMetricSample::getBufferPoolHitPercent),
                            averageLong(values, DatabaseMetricSample::getRowLockWaits)
                    );
                }).toList();
    }

    private <T> Double average(List<T> values, java.util.function.Function<T, Double> getter) {
        return values.stream().map(getter).filter(Objects::nonNull).mapToDouble(Double::doubleValue)
                .average().stream().boxed().findFirst().orElse(null);
    }

    private <T> Long averageLong(List<T> values, java.util.function.Function<T, Long> getter) {
        OptionalDouble average = values.stream().map(getter).filter(Objects::nonNull)
                .mapToLong(Long::longValue).average();
        return average.isPresent() ? Math.round(average.getAsDouble()) : null;
    }

    private LocalDateTime bucket(LocalDateTime time, int bucketMinutes) {
        LocalDateTime minute = time.truncatedTo(ChronoUnit.MINUTES);
        int bucketMinute = (minute.getMinute() / bucketMinutes) * bucketMinutes;
        return minute.withMinute(bucketMinute);
    }

    private Double value(ServerMetricSample sample, java.util.function.Function<ServerMetricSample, Double> getter) {
        return sample == null ? null : getter.apply(sample);
    }

    private Double value(ServerMetricSample sample, java.util.function.Function<ServerMetricSample, Double> getter,
                         List<String> enabledMetrics, String metric) {
        return serverMetricEnabled(enabledMetrics, metric) ? value(sample, getter) : null;
    }

    private boolean serverMetricEnabled(List<String> enabledMetrics, String metric) {
        return enabledMetrics == null || enabledMetrics.isEmpty() || enabledMetrics.contains(metric);
    }

    private void applyServerMetricSelection(ServerMetricSample sample, List<String> enabledMetrics) {
        if (!serverMetricEnabled(enabledMetrics, "CPU")) {
            sample.setCpuPercent(null);
        }
        if (!serverMetricEnabled(enabledMetrics, "MEMORY")) {
            sample.setMemoryTotalBytes(null);
            sample.setMemoryUsedBytes(null);
            sample.setMemoryPercent(null);
        }
        if (!serverMetricEnabled(enabledMetrics, "DISK")) {
            sample.setDiskTotalBytes(null);
            sample.setDiskUsedBytes(null);
            sample.setDiskPercent(null);
            sample.setDiskDetailsJson("[]");
        }
        if (!serverMetricEnabled(enabledMetrics, "LOAD")) {
            sample.setLoadOne(null);
        }
        if (!serverMetricEnabled(enabledMetrics, "NETWORK")) {
            sample.setNetworkRxBps(null);
            sample.setNetworkTxBps(null);
        }
        if (!serverMetricEnabled(enabledMetrics, "UPTIME")) {
            sample.setUptimeSeconds(null);
        }
    }

    private String text(Map<String, Object> params, String key) {
        Object value = params.get(key);
        return value == null ? null : String.valueOf(value);
    }

    private String firstText(Map<String, Object> params, String... keys) {
        for (String key : keys) {
            String value = text(params, key);
            if (value != null && !value.isBlank()) return value;
        }
        return null;
    }

    private Integer integer(Map<String, Object> params, String key) {
        try {
            String value = text(params, key);
            return value == null ? null : Integer.valueOf(value);
        } catch (Exception ignored) {
            return null;
        }
    }

    private int severityOrder(String severity) {
        if ("CRITICAL".equals(severity)) return 3;
        if ("WARNING".equals(severity)) return 2;
        return 1;
    }

    private record StatusView(String severity, String collectionState, LocalDateTime collectedAt) {}

    private record RangeSpec(Duration duration, int bucketMinutes) {
        static RangeSpec parse(String value) {
            String range = value == null ? "24h" : value.toLowerCase();
            return switch (range) {
                case "1h" -> new RangeSpec(Duration.ofHours(1), 1);
                case "7d" -> new RangeSpec(Duration.ofDays(7), 30);
                case "24h" -> new RangeSpec(Duration.ofHours(24), 5);
                default -> throw new IllegalArgumentException("range 仅支持 1h、24h、7d");
            };
        }
    }
}
