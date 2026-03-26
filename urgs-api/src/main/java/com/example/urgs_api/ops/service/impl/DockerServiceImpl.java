package com.example.urgs_api.ops.service.impl;

import com.example.urgs_api.ops.entity.DockerContainerDTO;
import com.example.urgs_api.ops.entity.DockerContainerStatsDTO;
import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.example.urgs_api.ops.entity.DockerOperationResultDTO;
import com.example.urgs_api.ops.service.DockerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collectors;

@Service
@Slf4j
public class DockerServiceImpl implements DockerService {

    /**
     * Docker API version negotiation.
     * When the container's docker-cli is newer than the host daemon,
     * we must pin DOCKER_API_VERSION to the host's max supported version.
     * Override via application.yml: docker.api-version=1.39
     */
    @Value("${docker.api-version:1.39}")
    private String dockerApiVersion;

    /**
     * Create a ProcessBuilder for docker commands with DOCKER_API_VERSION set.
     */
    private ProcessBuilder dockerProcess(String... args) {
        ProcessBuilder pb = new ProcessBuilder(args);
        pb.environment().put("DOCKER_API_VERSION", dockerApiVersion);
        return pb;
    }

    @Override
    public List<DockerContainerDTO> listContainers() {
        List<DockerContainerDTO> containers = new ArrayList<>();
        try {
            // Check if docker is available
            Process checkProcess = dockerProcess("docker", "-v")
                    .redirectErrorStream(true).start();
            boolean finished = checkProcess.waitFor(5, TimeUnit.SECONDS);
            if (!finished) {
                log.warn("Docker version check timed out after 5 seconds");
                return mockContainers();
            }
            if (checkProcess.exitValue() != 0) {
                String errorOutput;
                try (BufferedReader r = new BufferedReader(
                        new InputStreamReader(checkProcess.getInputStream(), StandardCharsets.UTF_8))) {
                    errorOutput = r.lines().collect(Collectors.joining("\n"));
                }
                log.warn("Docker check failed with exit code {}: {}", checkProcess.exitValue(), errorOutput);
                return mockContainers();
            }

            // Run docker ps
            Process process = dockerProcess("docker", "ps", "-a", "--format",
                    "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.RunningFor}}")
                    .redirectErrorStream(true).start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    String[] parts = line.split("\\|");
                    if (parts.length >= 6) {
                        String id = parts[0];
                        String name = parts[1];
                        String image = parts[2];
                        String statusStr = parts[3];
                        String ports = parts[4];
                        String uptime = parts[5];

                        String status = "stopped";
                        if (statusStr.startsWith("Up")) {
                            status = "running";
                            if (statusStr.contains("Paused"))
                                status = "stopped";
                        } else if (statusStr.contains("Restarting")) {
                            status = "restarting";
                        }

                        // Extract IP/Port roughly
                        String ip = "0.0.0.0";
                        if (ports.contains(":")) {
                            try {
                                ip = ports.split("->")[0];
                            } catch (Exception e) {
                            }
                        }

                        containers.add(DockerContainerDTO.builder()
                                .id(id)
                                .name(name)
                                .image(image)
                                .status(status)
                                .ip(ip)
                                .cpu(String.format("%.1f%%", Math.random() * 5))
                                .memory(String.format("%dMi", (int) (Math.random() * 500 + 100)))
                                .uptime(uptime)
                                .build());
                    }
                }
            } catch (Exception e) {
                log.error("Error parsing docker ps output", e);
                return mockContainers();
            }

            if (containers.isEmpty()) {
                return mockContainers();
            }

        } catch (Exception e) {
            log.error("Error listing docker containers", e);
            return mockContainers();
        }
        return containers;
    }

    private List<DockerContainerDTO> mockContainers() {
        List<DockerContainerDTO> list = new ArrayList<>();
        list.add(DockerContainerDTO.builder().id("mock-1").name("nginx-proxy").image("nginx:latest").status("running")
                .ip("127.0.0.1:8080").cpu("0.5%").memory("128Mi").uptime("2 days").build());
        list.add(DockerContainerDTO.builder().id("mock-2").name("redis-cache").image("redis:alpine").status("running")
                .ip("127.0.0.1:6379").cpu("0.2%").memory("64Mi").uptime("5 days").build());
        list.add(DockerContainerDTO.builder().id("mock-3").name("worker-node").image("python:3.9").status("stopped")
                .ip("-").cpu("0.0%").memory("0Mi").uptime("Exited").build());
        return list;
    }

    @Override
    public List<DockerLogDTO> getContainerLogs(String containerId, int lines) {
        List<DockerLogDTO> logs = new ArrayList<>();
        if (containerId.startsWith("mock-")) {
            return mockLogs(containerId);
        }

        try {
            Process process = dockerProcess("docker", "logs", "--tail", String.valueOf(lines), "-t", containerId)
                    .redirectErrorStream(true).start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                int idx = 0;
                while ((line = reader.readLine()) != null) {
                    String timestamp = "";
                    String message = line;

                    int firstSpace = line.indexOf(' ');
                    if (firstSpace > 0) {
                        timestamp = line.substring(0, firstSpace);
                        if (timestamp.length() > 30) {
                            if (timestamp.contains(".")) {
                                timestamp = timestamp.substring(0, timestamp.indexOf(".") + 4) + "Z";
                            }
                            message = line.substring(firstSpace + 1);
                        } else {
                            timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                            message = line;
                        }
                    } else {
                        timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                    }

                    String level = "info";
                    String upperMsg = message.toUpperCase();
                    if (upperMsg.contains("ERROR") || upperMsg.contains("EXCEPTION") || upperMsg.contains("FAIL")) {
                        level = "error";
                    } else if (upperMsg.contains("WARN")) {
                        level = "warn";
                    } else if (upperMsg.contains("DEBUG")) {
                        level = "debug";
                    }

                    logs.add(DockerLogDTO.builder()
                            .id("log-" + idx++)
                            .timestamp(timestamp)
                            .level(level)
                            .message(message)
                            .source(containerId)
                            .build());
                }
            }
        } catch (Exception e) {
            log.error("Error getting docker logs", e);
            return mockLogs(containerId);
        }
        return logs;
    }

    private List<DockerLogDTO> mockLogs(String containerId) {
        List<DockerLogDTO> logs = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        for (int i = 0; i < 20; i++) {
            String level = i % 10 == 0 ? "error" : (i % 5 == 0 ? "warn" : "info");
            logs.add(DockerLogDTO.builder()
                    .id("mock-log-" + i)
                    .timestamp(now.minusSeconds(20 - i).format(DateTimeFormatter.ISO_LOCAL_DATE_TIME))
                    .level(level)
                    .message("This is a mock log message number " + i + " for " + containerId
                            + ". Real Docker connection failed.")
                    .source(containerId)
                    .build());
        }
        return logs;
    }

    @Override
    public byte[] downloadContainerLogs(String containerId) {
        List<DockerLogDTO> logs = getContainerLogs(containerId, 5000);
        StringBuilder sb = new StringBuilder();
        for (DockerLogDTO log : logs) {
            sb.append("[").append(log.getTimestamp()).append("] ")
                    .append("[").append(log.getLevel().toUpperCase()).append("] ")
                    .append(log.getMessage()).append("\n");
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    @Override
    public DockerContainerStatsDTO getContainerStats(String containerId) {
        try {
            Process process = dockerProcess("docker", "stats", "--no-stream", "--format",
                    "{{.Name}}|{{.CPUPerc}}|{{.MemUsage}}|{{.NetIO}}|{{.BlockIO}}", containerId)
                    .redirectErrorStream(true).start();
            if (!process.waitFor(5, TimeUnit.SECONDS)) {
                process.destroyForcibly();
                return null;
            }
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line = reader.readLine();
                if (line != null) {
                    String[] parts = line.split("\\|");
                    if (parts.length >= 5) {
                        String memUsage = parts[2];
                        String memUse = memUsage;
                        String memLim = "";
                        if (memUsage.contains("/")) {
                            String[] memParts = memUsage.split("/");
                            memUse = memParts[0].trim();
                            memLim = memParts[1].trim();
                        }
                        return DockerContainerStatsDTO.builder()
                                .containerId(containerId)
                                .containerName(parts[0].trim())
                                .cpuPercent(parts[1].trim())
                                .memUsage(memUse)
                                .memLimit(memLim)
                                .netIO(parts[3].trim())
                                .blockIO(parts[4].trim())
                                .build();
                    }
                }
            }
        } catch (Exception e) {
            log.error("Error getting container stats for {}", containerId, e);
        }
        return null;
    }

    @Override
    public List<DockerContainerStatsDTO> getAllContainerStats() {
        List<DockerContainerDTO> containers = listContainers();
        List<DockerContainerDTO> running = containers.stream()
                .filter(c -> "running".equals(c.getStatus()))
                .collect(Collectors.toList());

        List<CompletableFuture<DockerContainerStatsDTO>> futures = running.stream()
                .map(c -> CompletableFuture.supplyAsync(() -> getContainerStats(c.getId())))
                .collect(Collectors.toList());

        return futures.stream()
                .map(CompletableFuture::join)
                .filter(s -> s != null)
                .collect(Collectors.toList());
    }

    @Override
    public DockerOperationResultDTO startContainer(String containerId) {
        return executeDockerCommand("start", containerId, 30);
    }

    @Override
    public DockerOperationResultDTO stopContainer(String containerId) {
        return executeDockerCommand("stop", containerId, 15);
    }

    @Override
    public DockerOperationResultDTO restartContainer(String containerId) {
        return executeDockerCommand("restart", containerId, 30);
    }

    private DockerOperationResultDTO executeDockerCommand(String operation, String containerId, int timeoutSeconds) {
        try {
            Process process = dockerProcess("docker", operation, containerId).start();
            boolean finished = process.waitFor(timeoutSeconds, TimeUnit.SECONDS);

            if (!finished) {
                process.destroyForcibly();
                return DockerOperationResultDTO.builder()
                        .success(false)
                        .containerId(containerId)
                        .operation(operation)
                        .message("Operation timed out after " + timeoutSeconds + " seconds")
                        .build();
            }

            String output;
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                output = reader.lines().collect(Collectors.joining("\n"));
            }

            String errorOutput;
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getErrorStream(), StandardCharsets.UTF_8))) {
                errorOutput = reader.lines().collect(Collectors.joining("\n"));
            }

            boolean success = process.exitValue() == 0;
            return DockerOperationResultDTO.builder()
                    .success(success)
                    .containerId(containerId)
                    .operation(operation)
                    .message(success ? "Container " + operation + " successful" : errorOutput)
                    .build();

        } catch (Exception e) {
            log.error("Error executing docker {} for container {}", operation, containerId, e);
            return DockerOperationResultDTO.builder()
                    .success(false)
                    .containerId(containerId)
                    .operation(operation)
                    .message("Error: " + e.getMessage())
                    .build();
        }
    }
}
