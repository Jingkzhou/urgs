package com.example.urgs_api.ops.service;

import com.example.urgs_api.ops.entity.DockerLogDTO;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
import java.util.Random;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;

@Service
@Slf4j
public class DockerLogStreamService {

    private final ExecutorService executor = Executors.newFixedThreadPool(10);
    private final Map<String, StreamHandle> activeStreams = new ConcurrentHashMap<>();
    private final AtomicInteger idCounter = new AtomicInteger(0);

    // Check if Docker is available (cached after first check)
    private volatile Boolean dockerAvailable = null;

    public static class StreamHandle {
        private final Process process; // null for mock streams
        private final Future<?> future;
        private final String containerId;

        StreamHandle(Process process, Future<?> future, String containerId) {
            this.process = process;
            this.future = future;
            this.containerId = containerId;
        }

        public void stop() {
            future.cancel(true);
            if (process != null) {
                process.destroyForcibly();
            }
        }
    }

    /**
     * Start streaming logs for a container.
     * Returns a stream key that can be used to stop the stream later.
     * Falls back to mock log stream if Docker is unavailable.
     */
    public String startStream(String containerId, Consumer<DockerLogDTO> callback) {
        String streamKey = containerId + "-" + System.currentTimeMillis();

        if (containerId.startsWith("mock-") || !isDockerAvailable()) {
            return startMockStream(streamKey, containerId, callback);
        }

        try {
            ProcessBuilder pb = new ProcessBuilder(
                    "docker", "logs", "--follow", "--tail", "100", "-t", containerId);
            pb.redirectErrorStream(true);
            Process process = pb.start();

            Future<?> future = executor.submit(() -> {
                try (BufferedReader reader = new BufferedReader(
                        new InputStreamReader(process.getInputStream(), StandardCharsets.UTF_8))) {
                    String line;
                    while (!Thread.currentThread().isInterrupted() && (line = reader.readLine()) != null) {
                        DockerLogDTO logEntry = parseLine(line, containerId);
                        callback.accept(logEntry);
                    }
                } catch (Exception e) {
                    if (!Thread.currentThread().isInterrupted()) {
                        log.error("Error reading docker log stream for container {}", containerId, e);
                    }
                } finally {
                    process.destroyForcibly();
                    activeStreams.remove(streamKey);
                }
            });

            StreamHandle handle = new StreamHandle(process, future, containerId);
            activeStreams.put(streamKey, handle);
            return streamKey;

        } catch (Exception e) {
            log.error("Failed to start docker log stream for container {}, falling back to mock", containerId, e);
            return startMockStream(streamKey, containerId, callback);
        }
    }

    /**
     * Start a mock log stream that generates simulated log entries.
     */
    private String startMockStream(String streamKey, String containerId, Consumer<DockerLogDTO> callback) {
        Future<?> future = executor.submit(() -> {
            String[] mockMessages = {
                    "Connection pool initialized with 10 connections",
                    "Incoming request: GET /api/v1/health",
                    "Request completed in 23ms",
                    "Scheduled task [cleanup] started",
                    "Cache hit ratio: 94.2%",
                    "WARNING: Memory usage at 78%",
                    "Processing batch job #" + (1000 + new Random().nextInt(9000)),
                    "Database query executed in 12ms",
                    "Session expired for user session-" + System.currentTimeMillis() % 1000,
                    "ERROR: Failed to connect to upstream service, retrying...",
                    "Retry successful, connection restored",
                    "Heartbeat check passed",
                    "Background worker processed 150 items",
                    "DEBUG: GC pause time 45ms",
                    "Static files served: 234 requests/min",
                    "New connection from 192.168.1." + (new Random().nextInt(254) + 1),
            };
            String[] levels = {"info", "info", "info", "info", "info", "warn", "info", "info", "info", "error", "info", "info", "info", "debug", "info", "info"};
            Random rand = new Random();

            try {
                // Send some initial "historical" logs quickly
                for (int i = 0; i < 15; i++) {
                    if (Thread.currentThread().isInterrupted()) return;
                    int idx = rand.nextInt(mockMessages.length);
                    DockerLogDTO entry = DockerLogDTO.builder()
                            .id("stream-" + idCounter.incrementAndGet())
                            .timestamp(LocalDateTime.now().minusSeconds(15 - i).format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")))
                            .level(levels[idx])
                            .message(mockMessages[idx])
                            .source(containerId)
                            .build();
                    callback.accept(entry);
                    Thread.sleep(50); // Small delay for initial batch
                }

                // Then send new logs every 2-5 seconds
                while (!Thread.currentThread().isInterrupted()) {
                    Thread.sleep(2000 + rand.nextInt(3000));
                    int idx = rand.nextInt(mockMessages.length);
                    DockerLogDTO entry = DockerLogDTO.builder()
                            .id("stream-" + idCounter.incrementAndGet())
                            .timestamp(LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss.SSS")))
                            .level(levels[idx])
                            .message(mockMessages[idx])
                            .source(containerId)
                            .build();
                    callback.accept(entry);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            } finally {
                activeStreams.remove(streamKey);
            }
        });

        StreamHandle handle = new StreamHandle(null, future, containerId);
        activeStreams.put(streamKey, handle);
        log.info("Started mock log stream for container {}", containerId);
        return streamKey;
    }

    private boolean isDockerAvailable() {
        if (dockerAvailable != null) return dockerAvailable;
        try {
            Process check = new ProcessBuilder("docker", "info")
                    .redirectErrorStream(true).start();
            boolean done = check.waitFor(5, java.util.concurrent.TimeUnit.SECONDS);
            if (!done) {
                check.destroyForcibly();
                dockerAvailable = false;
                log.warn("Docker daemon not reachable (timeout)");
            } else {
                dockerAvailable = check.exitValue() == 0;
                if (!dockerAvailable) {
                    String err;
                    try (BufferedReader r = new BufferedReader(
                            new InputStreamReader(check.getInputStream(), StandardCharsets.UTF_8))) {
                        err = r.lines().collect(java.util.stream.Collectors.joining("\n"));
                    }
                    log.warn("Docker daemon not available: {}", err);
                }
            }
        } catch (Exception e) {
            dockerAvailable = false;
            log.warn("Docker CLI not found: {}", e.getMessage());
        }
        return dockerAvailable;
    }

    public void stopStream(String streamKey) {
        StreamHandle handle = activeStreams.remove(streamKey);
        if (handle != null) {
            handle.stop();
            log.info("Stopped log stream: {}", streamKey);
        }
    }

    public void stopAllStreamsForContainer(String containerId) {
        activeStreams.entrySet().removeIf(entry -> {
            if (entry.getValue().containerId.equals(containerId)) {
                entry.getValue().stop();
                return true;
            }
            return false;
        });
    }

    private DockerLogDTO parseLine(String line, String containerId) {
        String timestamp;
        String message;

        int firstSpace = line.indexOf(' ');
        if (firstSpace > 0) {
            String possibleTs = line.substring(0, firstSpace);
            if (possibleTs.length() > 30) {
                timestamp = possibleTs.contains(".")
                        ? possibleTs.substring(0, possibleTs.indexOf(".") + 4) + "Z"
                        : possibleTs;
                message = line.substring(firstSpace + 1);
            } else {
                timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
                message = line;
            }
        } else {
            timestamp = LocalDateTime.now().format(DateTimeFormatter.ISO_LOCAL_DATE_TIME);
            message = line;
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

        return DockerLogDTO.builder()
                .id("stream-" + idCounter.incrementAndGet())
                .timestamp(timestamp)
                .level(level)
                .message(message)
                .source(containerId)
                .build();
    }

    @PreDestroy
    public void shutdown() {
        log.info("Shutting down DockerLogStreamService, stopping {} active streams", activeStreams.size());
        activeStreams.values().forEach(StreamHandle::stop);
        activeStreams.clear();
        executor.shutdownNow();
    }
}
