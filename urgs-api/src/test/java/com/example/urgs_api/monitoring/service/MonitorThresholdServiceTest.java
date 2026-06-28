package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.monitoring.entity.DatabaseMetricSample;
import com.example.urgs_api.monitoring.entity.MonitorTargetConfig;
import com.example.urgs_api.monitoring.entity.ServerMetricSample;
import com.example.urgs_api.monitoring.repository.MonitorTargetConfigRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class MonitorThresholdServiceTest {

    private MonitorTargetConfigRepository repository;
    private MonitorThresholdService service;

    @BeforeEach
    void setUp() {
        repository = mock(MonitorTargetConfigRepository.class);
        service = new MonitorThresholdService(repository, new ObjectMapper());
    }

    @Test
    void mergesGlobalThresholdsWithTargetOverride() {
        MonitorTargetConfig global = config("SERVER", 0L, true,
                "{\"cpuWarning\":80,\"cpuCritical\":90,\"memoryWarning\":80,\"enabledMetrics\":[\"CPU\",\"MEMORY\"]}");
        MonitorTargetConfig override = config("SERVER", 7L, true,
                "{\"cpuWarning\":70,\"enabledMetrics\":[\"DISK\"]}");
        when(repository.findByTargetTypeAndTargetId("SERVER", 0L)).thenReturn(Optional.of(global));
        when(repository.findByTargetTypeAndTargetId("SERVER", 7L)).thenReturn(Optional.of(override));

        MonitorThresholdService.ConfigView view = service.getConfig("server", 7L);

        assertThat(view.thresholds()).containsEntry("cpuWarning", 70d)
                .containsEntry("cpuCritical", 90d)
                .containsEntry("memoryWarning", 80d);
        assertThat(view.enabledMetrics()).containsExactly("DISK");
    }

    @Test
    void serverTargetDoesNotInheritGlobalEnabledState() {
        MonitorTargetConfig global = config("SERVER", 0L, true,
                "{\"cpuWarning\":80,\"cpuCritical\":90,\"enabledMetrics\":[\"CPU\",\"MEMORY\"]}");
        when(repository.findByTargetTypeAndTargetId("SERVER", 0L)).thenReturn(Optional.of(global));
        when(repository.findByTargetTypeAndTargetId("SERVER", 9L)).thenReturn(Optional.empty());

        MonitorThresholdService.ConfigView view = service.getConfig("SERVER", 9L);

        assertThat(view.enabled()).isFalse();
        assertThat(view.thresholds()).containsEntry("cpuWarning", 80d);
        assertThat(view.enabledMetrics()).containsExactly("CPU", "MEMORY");
    }

    @Test
    void evaluatesServerAndDatabaseSeverity() {
        ServerMetricSample server = new ServerMetricSample();
        server.setCpuPercent(91d);
        server.setMemoryPercent(50d);
        server.setDiskPercent(40d);
        assertThat(service.evaluateServer(server, Map.of(
                "cpuWarning", 80d, "cpuCritical", 90d,
                "memoryWarning", 80d, "memoryCritical", 90d,
                "diskWarning", 80d, "diskCritical", 90d
        ))).isEqualTo("CRITICAL");
        assertThat(service.evaluateServer(server, Map.of(
                "cpuWarning", 80d, "cpuCritical", 90d,
                "memoryWarning", 80d, "memoryCritical", 90d,
                "diskWarning", 80d, "diskCritical", 90d
        ), List.of("MEMORY", "DISK"))).isEqualTo("NORMAL");

        DatabaseMetricSample database = new DatabaseMetricSample();
        database.setThreadsConnected(75L);
        database.setMaxConnections(100L);
        database.setLatencyMs(50L);
        database.setRowLockWaits(0L);
        database.setSlowSqlAvgLatencyMs(1200d);
        assertThat(service.evaluateDatabase(database, Map.of(
                "connectionWarning", 70d, "connectionCritical", 90d,
                "latencyWarning", 200d, "latencyCritical", 1000d,
                "slowSqlWarning", 1000d, "slowSqlCritical", 3000d,
                "lockWaitWarning", 1d, "lockWaitCritical", 5d
        ))).isEqualTo("WARNING");
    }

    @Test
    void rejectsInvalidThresholdOrdering() {
        when(repository.findByTargetTypeAndTargetId("SERVER", 0L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> service.saveConfig("SERVER", 0L, true, Map.of(
                "cpuWarning", 95d,
                "cpuCritical", 90d
        ))).isInstanceOf(IllegalArgumentException.class)
                .hasMessageContaining("预警阈值");
    }

    private MonitorTargetConfig config(String type, Long targetId, boolean enabled, String json) {
        MonitorTargetConfig config = new MonitorTargetConfig();
        config.setTargetType(type);
        config.setTargetId(targetId);
        config.setEnabled(enabled);
        config.setThresholdsJson(json);
        return config;
    }
}
