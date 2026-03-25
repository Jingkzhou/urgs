package com.example.urgs_api.ops.service;

import com.example.urgs_api.ops.entity.DockerLogDTO;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.annotation.PreDestroy;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.nio.charset.StandardCharsets;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;
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

    public static class StreamHandle {
        private final Process process;
        private final Future<?> future;
        private final String containerId;

        StreamHandle(Process process, Future<?> future, String containerId) {
            this.process = process;
            this.future = future;
            this.containerId = containerId;
        }

        public void stop() {
            future.cancel(true);
            process.destroyForcibly();
        }
    }

    /**
     * Start streaming logs for a container.
     * Returns a stream key that can be used to stop the stream later.
     */
    public String startStream(String containerId, Consumer<DockerLogDTO> callback) {
        String streamKey = containerId + "-" + System.currentTimeMillis();

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
            log.error("Failed to start docker log stream for container {}", containerId, e);
            return null;
        }
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
