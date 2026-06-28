package com.example.urgs_api.monitoring.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.util.*;

@Component
public class LinuxMetricsParser {

    private final ObjectMapper objectMapper;

    public LinuxMetricsParser(ObjectMapper objectMapper) {
        this.objectMapper = objectMapper;
    }

    public Snapshot parse(String output) {
        Map<String, List<String>> sections = splitSections(output);
        long[] cpu = parseCpu(first(sections, "CPU"));
        Map<String, Long> memory = parseKeyValueKb(sections.get("MEM"));
        long memoryTotal = memory.getOrDefault("MemTotal", 0L);
        long memoryAvailable = memory.getOrDefault("MemAvailable",
                memory.getOrDefault("MemFree", 0L) + memory.getOrDefault("Buffers", 0L)
                        + memory.getOrDefault("Cached", 0L));
        long memoryUsed = Math.max(0, memoryTotal - memoryAvailable);
        List<DiskUsage> disks = parseDisks(sections.get("DISK"));
        long diskTotal = disks.stream().mapToLong(DiskUsage::totalBytes).sum();
        long diskUsed = disks.stream().mapToLong(DiskUsage::usedBytes).sum();
        long[] network = parseNetwork(sections.get("NET"));
        double loadOne = parseDouble(first(sections, "LOAD"), 0);
        long uptime = (long) parseDouble(first(sections, "UPTIME"), 0);

        return new Snapshot(
                cpu[0],
                cpu[1],
                memoryTotal * 1024,
                memoryUsed * 1024,
                diskTotal,
                diskUsed,
                disks,
                network[0],
                network[1],
                loadOne,
                uptime
        );
    }

    public String disksToJson(List<DiskUsage> disks) {
        try {
            return objectMapper.writeValueAsString(disks);
        } catch (JsonProcessingException e) {
            return "[]";
        }
    }

    static double cpuPercent(Snapshot previous, Snapshot current) {
        if (previous == null) return 0;
        long totalDelta = current.cpuTotal() - previous.cpuTotal();
        long idleDelta = current.cpuIdle() - previous.cpuIdle();
        if (totalDelta <= 0) return 0;
        return clampPercent((totalDelta - Math.max(0, idleDelta)) * 100d / totalDelta);
    }

    static long rate(long previous, long current, long seconds) {
        if (seconds <= 0 || current < previous) return 0;
        return (current - previous) / seconds;
    }

    static double percent(long used, long total) {
        return total <= 0 ? 0 : clampPercent(used * 100d / total);
    }

    private static double clampPercent(double value) {
        return Math.max(0, Math.min(100, value));
    }

    private Map<String, List<String>> splitSections(String output) {
        Map<String, List<String>> result = new LinkedHashMap<>();
        String current = null;
        for (String raw : Optional.ofNullable(output).orElse("").split("\\R")) {
            String line = raw.trim();
            if (line.startsWith("__") && line.endsWith("__") && line.length() > 4) {
                current = line.substring(2, line.length() - 2);
                result.putIfAbsent(current, new ArrayList<>());
            } else if (current != null && !line.isBlank()) {
                result.get(current).add(raw);
            }
        }
        return result;
    }

    private String first(Map<String, List<String>> sections, String section) {
        List<String> lines = sections.get(section);
        return lines == null || lines.isEmpty() ? "" : lines.get(0).trim();
    }

    private long[] parseCpu(String line) {
        String[] parts = line.trim().split("\\s+");
        if (parts.length < 5 || !"cpu".equals(parts[0])) return new long[]{0, 0};
        long total = 0;
        for (int i = 1; i < parts.length; i++) total += parseLong(parts[i], 0);
        long idle = parseLong(parts[4], 0) + (parts.length > 5 ? parseLong(parts[5], 0) : 0);
        return new long[]{total, idle};
    }

    private Map<String, Long> parseKeyValueKb(List<String> lines) {
        Map<String, Long> values = new HashMap<>();
        if (lines == null) return values;
        for (String line : lines) {
            String[] parts = line.trim().split("\\s+");
            if (parts.length >= 2) {
                values.put(parts[0].replace(":", ""), parseLong(parts[1], 0));
            }
        }
        return values;
    }

    private List<DiskUsage> parseDisks(List<String> lines) {
        List<DiskUsage> result = new ArrayList<>();
        if (lines == null) return result;
        for (String line : lines) {
            String trimmed = line.trim();
            if (trimmed.isBlank() || trimmed.startsWith("Filesystem")) continue;
            String[] parts = trimmed.split("\\s+");
            if (parts.length < 6) continue;
            long total = parseLong(parts[1], 0) * 1024;
            long used = parseLong(parts[2], 0) * 1024;
            String mountPoint = String.join(" ", Arrays.copyOfRange(parts, 5, parts.length));
            result.add(new DiskUsage(parts[0], mountPoint, total, used, percent(used, total)));
        }
        return result;
    }

    private long[] parseNetwork(List<String> lines) {
        long rx = 0;
        long tx = 0;
        if (lines == null) return new long[]{0, 0};
        for (String line : lines) {
            if (!line.contains(":")) continue;
            String[] side = line.trim().split(":", 2);
            if ("lo".equals(side[0].trim())) continue;
            String[] values = side[1].trim().split("\\s+");
            if (values.length >= 9) {
                rx += parseLong(values[0], 0);
                tx += parseLong(values[8], 0);
            }
        }
        return new long[]{rx, tx};
    }

    private long parseLong(String value, long fallback) {
        try {
            return Long.parseLong(value);
        } catch (Exception ignored) {
            return fallback;
        }
    }

    private double parseDouble(String value, double fallback) {
        try {
            return Double.parseDouble(value.trim().split("\\s+")[0]);
        } catch (Exception ignored) {
            return fallback;
        }
    }

    public record DiskUsage(String filesystem, String mountPoint, long totalBytes, long usedBytes,
                            double usedPercent) {}

    public record Snapshot(long cpuTotal, long cpuIdle, long memoryTotalBytes, long memoryUsedBytes,
                           long diskTotalBytes, long diskUsedBytes, List<DiskUsage> disks,
                           long networkRxBytes, long networkTxBytes, double loadOne, long uptimeSeconds) {}
}
