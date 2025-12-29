package com.example.urgs_api.metadata.service;

import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.File;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class LineageEngineService {

    @Value("${lineage.engine.workdir:${user.dir}/../sql-lineage-engine}")
    private String workDir;

    @Value("${lineage.engine.script:./run.sh}")
    private String scriptPath;

    @Value("${lineage.engine.args:parse-sql --file ./tests/sql --output neo4j}")
    private String engineArgs;

    @Value("${lineage.engine.log-file:}")
    private String logFile;

    @Value("${lineage.engine.stop-timeout-seconds:10}")
    private int stopTimeoutSeconds;

    private final Object lock = new Object();
    private Process process;
    private Instant lastStartedAt;
    private Instant lastStoppedAt;
    private Integer lastExitCode;
    private String lastError;

    public Map<String, Object> start() {
        synchronized (lock) {
            if (isRunning()) {
                return buildStatus(false, "引擎已在运行中");
            }
            try {
                Path workingDir = resolveWorkDir();
                Path script = resolveScriptPath(workingDir);
                if (!Files.exists(script)) {
                    lastError = "启动脚本不存在: " + script;
                    log.error(lastError);
                    return buildStatus(false, lastError);
                }

                Path logPath = resolveLogPath(workingDir);
                Files.createDirectories(logPath.getParent());

                List<String> command = new ArrayList<>();
                command.add("bash");
                command.add(script.toString());
                command.addAll(parseArgs(engineArgs));

                ProcessBuilder builder = new ProcessBuilder(command);
                builder.directory(workingDir.toFile());
                builder.redirectErrorStream(true);
                builder.redirectOutput(ProcessBuilder.Redirect.appendTo(logPath.toFile()));

                log.info("启动血缘引擎: workDir={}, command={}", workingDir, command);
                process = builder.start();
                lastStartedAt = Instant.now();
                lastStoppedAt = null;
                lastExitCode = null;
                lastError = null;

                watchProcess(process);
                return buildStatus(true, "引擎已启动");
            } catch (Exception e) {
                lastError = e.getMessage();
                log.error("启动血缘引擎失败", e);
                return buildStatus(false, "启动失败: " + e.getMessage());
            }
        }
    }

    public Map<String, Object> stop() {
        synchronized (lock) {
            if (!isRunning()) {
                return buildStatus(true, "引擎未在运行");
            }
            try {
                log.info("停止血缘引擎");
                stopProcess(process);
                return buildStatus(true, "引擎已停止");
            } catch (Exception e) {
                lastError = e.getMessage();
                log.error("停止血缘引擎失败", e);
                return buildStatus(false, "停止失败: " + e.getMessage());
            }
        }
    }

    public Map<String, Object> restart() {
        synchronized (lock) {
            log.info("重启血缘引擎");
            if (isRunning()) {
                stopProcess(process);
            }
            return start();
        }
    }

    public Map<String, Object> status() {
        synchronized (lock) {
            return buildStatus(true, null);
        }
    }

    public Map<String, Object> logs(int lines) {
        synchronized (lock) {
            Map<String, Object> result = new HashMap<>();
            try {
                log.info("读取血缘引擎日志: lines={}", lines);
                Path logPath = resolveLogPath(resolveWorkDir());
                if (!Files.exists(logPath)) {
                    result.put("success", true);
                    result.put("lines", List.of());
                    result.put("lineCount", 0);
                    return result;
                }
                List<String> allLines = Files.readAllLines(logPath, StandardCharsets.UTF_8);
                int fromIndex = Math.max(0, allLines.size() - lines);
                List<String> tail = allLines.subList(fromIndex, allLines.size());
                result.put("success", true);
                result.put("lines", tail);
                result.put("lineCount", tail.size());
                return result;
            } catch (Exception e) {
                log.error("读取血缘引擎日志失败", e);
                result.put("success", false);
                result.put("error", e.getMessage());
                result.put("lines", List.of());
                return result;
            }
        }
    }

    private boolean isRunning() {
        return process != null && process.isAlive();
    }

    private void stopProcess(Process running) {
        if (running == null) {
            return;
        }
        running.destroy();
        try {
            if (!running.waitFor(stopTimeoutSeconds, TimeUnit.SECONDS)) {
                running.destroyForcibly();
                running.waitFor(stopTimeoutSeconds, TimeUnit.SECONDS);
            }
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        } finally {
            lastStoppedAt = Instant.now();
            if (!running.isAlive()) {
                try {
                    lastExitCode = running.exitValue();
                } catch (IllegalThreadStateException ignore) {
                    lastExitCode = null;
                }
            }
            if (process == running) {
                process = null;
            }
        }
    }

    private void watchProcess(Process running) {
        Thread watcher = new Thread(() -> {
            try {
                int exitCode = running.waitFor();
                synchronized (lock) {
                    if (process == running) {
                        lastExitCode = exitCode;
                        lastStoppedAt = Instant.now();
                        process = null;
                    }
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "lineage-engine-watcher");
        watcher.setDaemon(true);
        watcher.start();
    }

    private Map<String, Object> buildStatus(boolean success, String message) {
        Map<String, Object> status = new HashMap<>();
        status.put("success", success);
        status.put("status", isRunning() ? "running" : "stopped");
        if (process != null && process.isAlive()) {
            status.put("pid", process.pid());
        }
        if (lastStartedAt != null) {
            status.put("lastStartedAt", lastStartedAt.toString());
        }
        if (lastStoppedAt != null) {
            status.put("lastStoppedAt", lastStoppedAt.toString());
        }
        if (lastExitCode != null) {
            status.put("lastExitCode", lastExitCode);
        }
        if (StringUtils.hasText(lastError)) {
            status.put("error", lastError);
        }
        if (StringUtils.hasText(message)) {
            status.put("message", message);
        }
        return status;
    }

    private Path resolveWorkDir() {
        if (!StringUtils.hasText(workDir)) {
            return Paths.get(System.getProperty("user.dir")).toAbsolutePath().normalize();
        }
        return Paths.get(workDir).toAbsolutePath().normalize();
    }

    private Path resolveScriptPath(Path workingDir) {
        Path script = Paths.get(scriptPath);
        if (!script.isAbsolute()) {
            script = workingDir.resolve(scriptPath);
        }
        return script.toAbsolutePath().normalize();
    }

    private Path resolveLogPath(Path workingDir) {
        if (StringUtils.hasText(logFile)) {
            return Paths.get(logFile).toAbsolutePath().normalize();
        }
        return workingDir.resolve("logs").resolve("lineage-engine.log").toAbsolutePath().normalize();
    }

    private List<String> parseArgs(String args) {
        List<String> result = new ArrayList<>();
        if (!StringUtils.hasText(args)) {
            return result;
        }
        StringBuilder current = new StringBuilder();
        boolean inQuotes = false;
        char quoteChar = '\0';
        for (int i = 0; i < args.length(); i++) {
            char c = args.charAt(i);
            if ((c == '"' || c == '\'') && (quoteChar == '\0' || quoteChar == c)) {
                if (inQuotes && quoteChar == c) {
                    inQuotes = false;
                    quoteChar = '\0';
                } else if (!inQuotes) {
                    inQuotes = true;
                    quoteChar = c;
                } else {
                    current.append(c);
                }
                continue;
            }
            if (!inQuotes && Character.isWhitespace(c)) {
                if (current.length() > 0) {
                    result.add(current.toString());
                    current.setLength(0);
                }
                continue;
            }
            current.append(c);
        }
        if (current.length() > 0) {
            result.add(current.toString());
        }
        return result;
    }
}
