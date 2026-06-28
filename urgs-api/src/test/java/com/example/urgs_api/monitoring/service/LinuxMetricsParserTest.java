package com.example.urgs_api.monitoring.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import static org.assertj.core.api.Assertions.assertThat;

class LinuxMetricsParserTest {

    private final LinuxMetricsParser parser = new LinuxMetricsParser(new ObjectMapper());

    @Test
    void parsesLinuxProcAndDiskSnapshot() {
        String output = """
                __CPU__
                cpu  100 10 20 870 0 0 0 0 0 0
                __MEM__
                MemTotal:       1000000 kB
                MemFree:         100000 kB
                MemAvailable:    400000 kB
                Buffers:          10000 kB
                Cached:          200000 kB
                __LOAD__
                1.25 1.00 0.75 1/100 123
                __DISK__
                Filesystem 1024-blocks Used Available Capacity Mounted on
                /dev/sda1 1000000 400000 600000 40% /
                tmpfs 1000 100 900 10% /run
                __NET__
                Inter-| Receive | Transmit
                 eth0: 10000 0 0 0 0 0 0 0 20000 0 0 0 0 0 0 0
                   lo: 99999 0 0 0 0 0 0 0 99999 0 0 0 0 0 0 0
                __UPTIME__
                86461.00 100.00
                """;

        LinuxMetricsParser.Snapshot snapshot = parser.parse(output);

        assertThat(snapshot.cpuTotal()).isEqualTo(1000);
        assertThat(snapshot.cpuIdle()).isEqualTo(870);
        assertThat(snapshot.memoryTotalBytes()).isEqualTo(1_024_000_000L);
        assertThat(snapshot.memoryUsedBytes()).isEqualTo(614_400_000L);
        assertThat(snapshot.diskTotalBytes()).isEqualTo(1_025_024_000L);
        assertThat(snapshot.networkRxBytes()).isEqualTo(10_000);
        assertThat(snapshot.networkTxBytes()).isEqualTo(20_000);
        assertThat(snapshot.loadOne()).isEqualTo(1.25);
        assertThat(snapshot.uptimeSeconds()).isEqualTo(86_461);
    }

    @Test
    void calculatesCpuAndNetworkDeltasSafely() {
        LinuxMetricsParser.Snapshot previous = new LinuxMetricsParser.Snapshot(
                1000, 800, 0, 0, 0, 0, java.util.List.of(), 1000, 2000, 0, 0);
        LinuxMetricsParser.Snapshot current = new LinuxMetricsParser.Snapshot(
                1200, 900, 0, 0, 0, 0, java.util.List.of(), 3000, 5000, 0, 0);

        assertThat(LinuxMetricsParser.cpuPercent(previous, current)).isEqualTo(50);
        assertThat(LinuxMetricsParser.rate(1000, 3000, 2)).isEqualTo(1000);
        assertThat(LinuxMetricsParser.rate(3000, 1000, 2)).isZero();
    }
}
