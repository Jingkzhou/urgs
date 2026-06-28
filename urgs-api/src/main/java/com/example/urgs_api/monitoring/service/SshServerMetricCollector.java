package com.example.urgs_api.monitoring.service;

import com.example.urgs_api.monitoring.entity.ServerMetricSample;
import com.example.urgs_api.ops.entity.InfrastructureAsset;
import com.example.urgs_api.ops.entity.InfrastructureUser;
import com.jcraft.jsch.ChannelExec;
import com.jcraft.jsch.JSch;
import com.jcraft.jsch.Session;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.LocalDateTime;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Component
public class SshServerMetricCollector {

    private static final String METRIC_COMMAND = """
            printf '__CPU__\\n'; head -n 1 /proc/stat;
            printf '__MEM__\\n'; cat /proc/meminfo;
            printf '__LOAD__\\n'; cat /proc/loadavg;
            printf '__DISK__\\n'; df -Pk -x tmpfs -x devtmpfs -x squashfs;
            printf '__NET__\\n'; cat /proc/net/dev;
            printf '__UPTIME__\\n'; cat /proc/uptime
            """;

    private final LinuxMetricsParser parser;
    private final Map<Long, TimedSnapshot> previousSnapshots = new ConcurrentHashMap<>();
    private final String knownHostsPath;
    private final int connectTimeoutMs;

    public SshServerMetricCollector(
            LinuxMetricsParser parser,
            @Value("${monitoring.ssh.known-hosts:${user.home}/.ssh/known_hosts}") String knownHostsPath,
            @Value("${monitoring.ssh.connect-timeout-ms:8000}") int connectTimeoutMs) {
        this.parser = parser;
        this.knownHostsPath = knownHostsPath;
        this.connectTimeoutMs = connectTimeoutMs;
    }

    public ServerMetricSample collect(InfrastructureAsset asset, InfrastructureUser credential) {
        LocalDateTime collectedAt = LocalDateTime.now();
        try {
            String output = execute(asset.getInternalIp(), credential);
            LinuxMetricsParser.Snapshot snapshot = parser.parse(output);
            TimedSnapshot previous = previousSnapshots.put(asset.getId(), new TimedSnapshot(snapshot, collectedAt));
            long seconds = previous == null ? 0
                    : Math.max(1, Duration.between(previous.collectedAt(), collectedAt).toSeconds());

            ServerMetricSample sample = baseSample(asset.getId(), collectedAt, "LIVE");
            sample.setCpuPercent(LinuxMetricsParser.cpuPercent(
                    previous == null ? null : previous.snapshot(), snapshot));
            sample.setLoadOne(snapshot.loadOne());
            sample.setMemoryTotalBytes(snapshot.memoryTotalBytes());
            sample.setMemoryUsedBytes(snapshot.memoryUsedBytes());
            sample.setMemoryPercent(LinuxMetricsParser.percent(
                    snapshot.memoryUsedBytes(), snapshot.memoryTotalBytes()));
            sample.setDiskTotalBytes(snapshot.diskTotalBytes());
            sample.setDiskUsedBytes(snapshot.diskUsedBytes());
            sample.setDiskPercent(LinuxMetricsParser.percent(snapshot.diskUsedBytes(), snapshot.diskTotalBytes()));
            sample.setDiskDetailsJson(parser.disksToJson(snapshot.disks()));
            sample.setNetworkRxBps(previous == null ? 0
                    : LinuxMetricsParser.rate(previous.snapshot().networkRxBytes(), snapshot.networkRxBytes(), seconds));
            sample.setNetworkTxBps(previous == null ? 0
                    : LinuxMetricsParser.rate(previous.snapshot().networkTxBytes(), snapshot.networkTxBytes(), seconds));
            sample.setUptimeSeconds(snapshot.uptimeSeconds());
            return sample;
        } catch (Exception e) {
            ServerMetricSample sample = baseSample(asset.getId(), collectedAt, "UNAVAILABLE");
            sample.setSeverity("CRITICAL");
            sample.setErrorMessage(sanitize(e.getMessage()));
            return sample;
        }
    }

    private String execute(String host, InfrastructureUser credential) throws Exception {
        if (host == null || host.isBlank()) {
            throw new IllegalArgumentException("缺少服务器内网IP");
        }
        if (credential == null || credential.getUsername() == null || credential.getUsername().isBlank()) {
            throw new IllegalArgumentException("缺少操作系统账号");
        }
        if (credential.getPassword() == null || credential.getPassword().isBlank()) {
            throw new IllegalArgumentException("SSH账号未配置密码");
        }

        Path knownHosts = Path.of(knownHostsPath.replaceFirst("^~", System.getProperty("user.home")));
        if (!Files.isRegularFile(knownHosts)) {
            throw new IllegalStateException("SSH known_hosts 文件不存在");
        }

        JSch jsch = new JSch();
        jsch.setKnownHosts(knownHosts.toString());
        Session session = null;
        ChannelExec channel = null;
        try {
            session = jsch.getSession(credential.getUsername(), host, 22);
            session.setPassword(credential.getPassword());
            session.setConfig("StrictHostKeyChecking", "yes");
            session.setConfig("PreferredAuthentications", "publickey,keyboard-interactive,password");
            session.connect(connectTimeoutMs);

            channel = (ChannelExec) session.openChannel("exec");
            channel.setCommand(METRIC_COMMAND);
            channel.setInputStream(null);
            try (InputStream input = channel.getInputStream();
                 InputStream error = channel.getErrStream();
                 ByteArrayOutputStream output = new ByteArrayOutputStream()) {
                channel.connect(connectTimeoutMs);
                long deadline = System.currentTimeMillis() + connectTimeoutMs;
                byte[] buffer = new byte[4096];
                while (System.currentTimeMillis() < deadline) {
                    while (input.available() > 0) {
                        int read = input.read(buffer);
                        if (read > 0) output.write(buffer, 0, read);
                    }
                    if (channel.isClosed()) break;
                    Thread.sleep(50);
                }
                if (!channel.isClosed()) {
                    throw new IllegalStateException("SSH指标采集超时");
                }
                if (channel.getExitStatus() != 0) {
                    byte[] errorBytes = error == null ? new byte[0] : error.readAllBytes();
                    throw new IllegalStateException("SSH指标命令执行失败: " + new String(errorBytes));
                }
                return output.toString();
            }
        } finally {
            if (channel != null) channel.disconnect();
            if (session != null) session.disconnect();
        }
    }

    private ServerMetricSample baseSample(Long assetId, LocalDateTime collectedAt, String state) {
        ServerMetricSample sample = new ServerMetricSample();
        sample.setAssetId(assetId);
        sample.setCollectedAt(collectedAt);
        sample.setCollectionState(state);
        sample.setSeverity("NORMAL");
        return sample;
    }

    private String sanitize(String value) {
        if (value == null || value.isBlank()) return "服务器指标采集失败";
        String sanitized = value.replaceAll("[\\r\\n\\t]+", " ").trim();
        return sanitized.length() > 500 ? sanitized.substring(0, 500) : sanitized;
    }

    private record TimedSnapshot(LinuxMetricsParser.Snapshot snapshot, LocalDateTime collectedAt) {}
}
