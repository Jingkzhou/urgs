package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.service.DataSourceService;
import com.example.urgs_api.monitoring.dto.MonitoringDtos;
import com.example.urgs_api.monitoring.repository.DatabaseMetricSampleRepository;
import com.example.urgs_api.monitoring.repository.ServerMetricSampleRepository;
import com.example.urgs_api.monitoring.repository.SlowSqlSampleRepository;
import com.example.urgs_api.ops.entity.InfrastructureAsset;
import com.example.urgs_api.ops.repository.InfrastructureAssetRepository;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;

import java.util.List;
import java.util.Map;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.verifyNoInteractions;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class SystemMonitoringServiceTest {

    @Mock
    private InfrastructureAssetRepository assetRepository;
    @Mock
    private DataSourceService dataSourceService;
    @Mock
    private ServerMetricSampleRepository serverSampleRepository;
    @Mock
    private DatabaseMetricSampleRepository databaseSampleRepository;
    @Mock
    private SlowSqlSampleRepository slowSqlSampleRepository;
    @Mock
    private SshServerMetricCollector serverCollector;
    @Mock
    private MySqlMetricCollector mysqlCollector;
    @Mock
    private MonitorThresholdService thresholdService;

    private SystemMonitoringService service;

    @BeforeEach
    void setUp() {
        service = new SystemMonitoringService(
                assetRepository,
                dataSourceService,
                serverSampleRepository,
                databaseSampleRepository,
                slowSqlSampleRepository,
                serverCollector,
                mysqlCollector,
                thresholdService,
                new ObjectMapper(),
                Runnable::run,
                60_000L
        );
    }

    @Test
    void rejectsManualDatabaseCollectionWhenTargetIsPaused() {
        DataSourceConfig datasource = new DataSourceConfig();
        datasource.setId(7L);
        datasource.setStatus(1);
        datasource.setTypeCode("mysql");
        when(dataSourceService.getAllConfigs()).thenReturn(List.of(datasource));
        when(thresholdService.getConfig(MonitorThresholdService.DATABASE, 7L))
                .thenReturn(new MonitorThresholdService.ConfigView(
                        MonitorThresholdService.DATABASE, 7L, false, Map.<String, Double>of(), List.of()));

        boolean accepted = service.collectAsync("DATABASE", 7L);

        assertThat(accepted).isFalse();
        verifyNoInteractions(mysqlCollector);
    }

    @Test
    void serverListOmitsDisabledTargetsUnlessRequestedForConfiguration() {
        InfrastructureAsset enabledAsset = new InfrastructureAsset();
        enabledAsset.setId(1L);
        enabledAsset.setHostname("enabled-host");
        enabledAsset.setInternalIp("10.0.0.1");
        enabledAsset.setStatus("active");
        enabledAsset.setOsType("Linux");

        InfrastructureAsset disabledAsset = new InfrastructureAsset();
        disabledAsset.setId(2L);
        disabledAsset.setHostname("disabled-host");
        disabledAsset.setInternalIp("10.0.0.2");
        disabledAsset.setStatus("active");
        disabledAsset.setOsType("Linux");

        when(assetRepository.findAll()).thenReturn(List.of(enabledAsset, disabledAsset));
        when(serverSampleRepository.findTopByAssetIdOrderByCollectedAtDesc(1L)).thenReturn(Optional.empty());
        when(serverSampleRepository.findTopByAssetIdOrderByCollectedAtDesc(2L)).thenReturn(Optional.empty());
        when(thresholdService.getConfig(MonitorThresholdService.SERVER, 1L))
                .thenReturn(new MonitorThresholdService.ConfigView(
                        MonitorThresholdService.SERVER, 1L, true, Map.<String, Double>of(), List.of()));
        when(thresholdService.getConfig(MonitorThresholdService.SERVER, 2L))
                .thenReturn(new MonitorThresholdService.ConfigView(
                        MonitorThresholdService.SERVER, 2L, false, Map.<String, Double>of(), List.of()));

        List<String> visibleHosts = service.listServers(null, null, null, false).stream()
                .map(MonitoringDtos.ServerSummary::hostname)
                .toList();
        List<String> configurableHosts = service.listServers(null, null, null, true).stream()
                .map(MonitoringDtos.ServerSummary::hostname)
                .toList();

        assertThat(visibleHosts).containsExactly("enabled-host");
        assertThat(configurableHosts).containsExactlyInAnyOrder("disabled-host", "enabled-host");
    }

    @Test
    void databaseListFiltersByBoundSystemAndEnvironment() {
        DataSourceConfig matched = new DataSourceConfig();
        matched.setId(11L);
        matched.setName("matched-mysql");
        matched.setStatus(1);
        matched.setTypeCode("mysql");
        matched.setAppSystemId(100L);
        matched.setEnvId(200L);

        DataSourceConfig otherSystem = new DataSourceConfig();
        otherSystem.setId(12L);
        otherSystem.setName("other-mysql");
        otherSystem.setStatus(1);
        otherSystem.setTypeCode("mysql");
        otherSystem.setAppSystemId(101L);
        otherSystem.setEnvId(200L);

        when(dataSourceService.getAllConfigs()).thenReturn(List.of(matched, otherSystem));
        when(databaseSampleRepository.findTopByDatasourceIdOrderByCollectedAtDesc(11L)).thenReturn(Optional.empty());
        when(thresholdService.getConfig(MonitorThresholdService.DATABASE, 11L))
                .thenReturn(new MonitorThresholdService.ConfigView(
                        MonitorThresholdService.DATABASE, 11L, true, Map.<String, Double>of(), List.of()));

        List<String> names = service.listDatabases(100L, 200L, null).stream()
                .map(MonitoringDtos.DatabaseSummary::name)
                .toList();

        assertThat(names).containsExactly("matched-mysql");
    }
}
