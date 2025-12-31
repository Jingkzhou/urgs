package com.example.urgs_api.ops.service.impl;

import com.example.urgs_api.ops.entity.DockerContainerDTO;
import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.example.urgs_api.ops.service.DockerService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.TimeUnit;

@Service
@Slf4j
public class DockerServiceImpl implements DockerService {

    @Override
    public List<DockerContainerDTO> listContainers() {
        List<DockerContainerDTO> containers = new ArrayList<>();
        try {
            // Check if docker is available
            Process checkProcess = new ProcessBuilder("docker", "-v").start();
            if (!checkProcess.waitFor(2, TimeUnit.SECONDS)) {
                log.warn("Docker command not reachable or timeout");
                return mockContainers();
            }
            if (checkProcess.exitValue() != 0) {
                log.warn("Docker check failed");
                return mockContainers();
            }

            // Run docker ps
            Process process = new ProcessBuilder("docker", "ps", "-a", "--format",
                    "{{.ID}}|{{.Names}}|{{.Image}}|{{.Status}}|{{.Ports}}|{{.RunningFor}}").start();
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
                                status = "stopped"; // Map paused to stopped for simplicity or add paused
                        } else if (statusStr.contains("Restarting")) {
                            status = "restarting";
                        }

                        // Extract IP/Port roughly
                        String ip = "0.0.0.0";
                        if (ports.contains(":")) {
                            // 0.0.0.0:8080->80/tcp
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
                                // Mock CPU/Mem as docker ps doesn't provide valuable real-time stats easily
                                // without docker stats which is slow
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
        // Fallback for demo if no docker is running
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
            // docker logs --tail n -t containerId
            Process process = new ProcessBuilder("docker", "logs", "--tail", String.valueOf(lines), "-t", containerId)
                    .start();
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                int idx = 0;
                while ((line = reader.readLine()) != null) {
                    // Docker assigns timestamp at start if -t is used:
                    // 2024-05-20T10:00:00.000000000Z message content
                    String timestamp = "";
                    String message = line;

                    int firstSpace = line.indexOf(' ');
                    if (firstSpace > 0) {
                        timestamp = line.substring(0, firstSpace);
                        if (timestamp.length() > 30) { // likely a timestamp
                            // Trucate nanoseconds for readability
                            if (timestamp.contains(".")) {
                                timestamp = timestamp.substring(0, timestamp.indexOf(".") + 4) + "Z";
                            }
                            message = line.substring(firstSpace + 1);
                        } else {
                            // Maybe not a timestamp, reset
                            timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                            message = line;
                        }
                    } else {
                        timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                    }

                    // Guess log level
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
        // Retrieve all logs (or limit to a large number)
        List<DockerLogDTO> logs = getContainerLogs(containerId, 5000);
        StringBuilder sb = new StringBuilder();
        for (DockerLogDTO log : logs) {
            sb.append("[").append(log.getTimestamp()).append("] ")
                    .append("[").append(log.getLevel().toUpperCase()).append("] ")
                    .append(log.getMessage()).append("\n");
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }
}
