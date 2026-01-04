package com.example.urgs_api.metadata.service;

import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.metadata.mapper.LineageAnalysisRecordMapper;
import com.example.urgs_api.metadata.model.LineageAnalysisRecord;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.io.InputStream;
import java.nio.file.StandardCopyOption;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
@RequiredArgsConstructor
public class LineageEngineService {

    private final GitPlatformService gitPlatformService;
    private final LineageAnalysisRecordMapper analysisRecordMapper;

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
    private StartEngineRequest lastRequest;
    private String lastRecordId;

    public Map<String, Object> start(StartEngineRequest request) {
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

                // Prepare Input Paths (Git Source)
                String inputPath;
                String repoRoot = null;

                if (request != null && request.getRepoId() != null) {
                    GitInputResult result = prepareGitInput(request);
                    inputPath = result.inputPath();
                    repoRoot = result.repoRoot();
                } else {
                    inputPath = resolveEngineArgsPath(engineArgs);
                }

                // Create record first to get ID and SHA
                String recordId = null;
                LineageAnalysisRecord record = null;
                if (request != null && request.getRepoId() != null) {
                    record = createAnalysisRecord(request, Instant.now());
                    recordId = record.getId();
                    this.lastRequest = request;
                    this.lastRecordId = recordId;
                }

                Path logPath = resolveLogPath(workingDir, recordId);
                Files.createDirectories(logPath.getParent());

                List<String> command = new ArrayList<>();
                command.add("bash");
                command.add(script.toString());

                // Construct command line arguments
                command.add("parse-sql");
                command.add("--file");
                command.add(inputPath);

                // Pass metadata arguments if available
                if (request != null && request.getRepoId() != null) {
                    if (recordId != null) {
                        command.add("--version-id");
                        command.add(recordId);
                    }
                    command.add("--repo-id");
                    command.add(String.valueOf(request.getRepoId()));

                    if (StringUtils.hasText(request.getRef())) {
                        command.add("--ref");
                        command.add(request.getRef());
                    }

                    if (record != null && StringUtils.hasText(record.getCommitSha())) {
                        command.add("--commit-sha");
                        command.add(record.getCommitSha());
                    }
                } // SHA.

                if (repoRoot != null) {
                    command.add("--repo-root");
                    command.add(repoRoot);
                }

                if (request != null && StringUtils.hasText(request.getUser())) {
                    command.add("--default-user");
                    command.add(request.getUser());
                }
                if (request != null && StringUtils.hasText(request.getLanguage())) {
                    command.add("--dialect");
                    command.add(request.getLanguage());
                }

                command.add("--output");
                command.add("neo4j");

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

                watchProcess(process, recordId, logPath);
                return buildStatus(true, "引擎已启动");
            } catch (Exception e) {
                lastError = e.getMessage();
                log.error("启动血缘引擎失败", e);
                return buildStatus(false, "启动失败: " + e.getMessage());
            }
        }
    }

    private record GitInputResult(String inputPath, String repoRoot) {
    }

    private GitInputResult prepareGitInput(StartEngineRequest request) throws Exception {
        Path tempDir = Files.createTempDirectory("lineage-git-");
        log.info("下载代码归档到临时目录: {}", tempDir);

        try (InputStream is = gitPlatformService.downloadArchive(request.getRepoId(), request.getRef());
                ZipInputStream zis = new ZipInputStream(is)) {

            ZipEntry entry;
            String rootDir = null;
            while ((entry = zis.getNextEntry()) != null) {
                if (rootDir == null && entry.isDirectory()) {
                    rootDir = entry.getName();
                }
                Path outPath = tempDir.resolve(entry.getName());
                if (entry.isDirectory()) {
                    Files.createDirectories(outPath);
                } else {
                    Files.createDirectories(outPath.getParent());
                    Files.copy(zis, outPath, StandardCopyOption.REPLACE_EXISTING);
                }
                zis.closeEntry();
            }

            Path realBase = rootDir != null ? tempDir.resolve(rootDir) : tempDir;

            if (request.getPaths() != null && !request.getPaths().isEmpty()) {
                if (request.getPaths().size() == 1) {
                    // Single path: use it directly, repoRoot is realBase
                    return new GitInputResult(
                            realBase.resolve(request.getPaths().get(0)).toAbsolutePath().toString(),
                            realBase.toAbsolutePath().toString());
                } else {
                    // Multiple paths: copy to collection dir preserving structure
                    Path collectionDir = tempDir.resolve("collect");
                    Files.createDirectories(collectionDir);
                    for (String p : request.getPaths()) {
                        Path src = realBase.resolve(p);
                        if (Files.exists(src)) {
                            // Use full relative path to preserve structure (e.g. src/main/A.sql)
                            // Note: p is already relative to repo root
                            Path dest = collectionDir.resolve(p);
                            Files.createDirectories(dest.getParent());

                            if (Files.isDirectory(src)) {
                                copyDirectory(src, dest);
                            } else {
                                Files.copy(src, dest, StandardCopyOption.REPLACE_EXISTING);
                            }
                        }
                    }
                    // For collection dir, the root is the collection dir itself
                    // because we reconstructed the structure inside it.
                    return new GitInputResult(
                            collectionDir.toAbsolutePath().toString(),
                            collectionDir.toAbsolutePath().toString());
                }
            }

            return new GitInputResult(
                    realBase.toAbsolutePath().toString(),
                    realBase.toAbsolutePath().toString());
        }
    }

    private void copyDirectory(Path source, Path target) throws Exception {
        Files.walk(source).forEach(path -> {
            try {
                Path destPath = target.resolve(source.relativize(path));
                if (Files.isDirectory(path)) {
                    Files.createDirectories(destPath);
                } else {
                    Files.copy(path, destPath, StandardCopyOption.REPLACE_EXISTING);
                }
            } catch (Exception e) {
                throw new RuntimeException(e);
            }
        });
    }

    private String resolveEngineArgsPath(String argsStr) {
        List<String> args = parseArgs(argsStr);
        for (int i = 0; i < args.size(); i++) {
            if ("--file".equals(args.get(i)) && i + 1 < args.size()) {
                return args.get(i + 1);
            }
        }
        return "./tests/sql";
    }

    private LineageAnalysisRecord createAnalysisRecord(StartEngineRequest request, Instant startTime) {
        LineageAnalysisRecord record = new LineageAnalysisRecord();
        record.setRepoId(request.getRepoId());
        record.setRef(request.getRef());
        record.setPaths(request.getPaths());
        record.setDefaultUser(request.getUser());
        record.setLanguage(request.getLanguage());
        record.setStatus("RUNNING");
        record.setStartTime(LocalDateTime.now());
        record.setCreateTime(LocalDateTime.now());
        record.setUpdateTime(LocalDateTime.now());

        // Try to fetch current commit SHA for the ref
        try {
            var latestCommit = gitPlatformService.getLatestCommit(request.getRepoId(), request.getRef());
            if (latestCommit != null) {
                record.setCommitSha(latestCommit.getSha());
            }
        } catch (Exception e) {
            log.warn("无法获取 Git 最新提交 SHA: {}", e.getMessage());
        }

        analysisRecordMapper.insert(record);
        return record;
    }

    public Map<String, Object> stop() {
        synchronized (lock) {
            // 注意：不再检查 isRunning()，因为 docker exec 启动的容器内进程
            // 与 Java 端的 process 对象状态是独立的。
            // bridge.sh 会执行 docker exec 后立即返回，但容器中的 Python 进程仍在运行。
            // 所以我们始终尝试执行 kill 脚本，让脚本自己判断是否有进程需要终止。
            try {
                log.info("停止血缘引擎");

                // Execute kill command via bridge script
                Path workingDir = resolveWorkDir();
                Path script = resolveScriptPath(workingDir);
                if (Files.exists(script)) {
                    List<String> command = new ArrayList<>();
                    command.add("bash");
                    command.add(script.toString());
                    command.add("--kill-engine");

                    ProcessBuilder builder = new ProcessBuilder(command);
                    builder.directory(workingDir.toFile());
                    builder.redirectErrorStream(true); // 合并 stdout 和 stderr
                    Process killProcess = builder.start();

                    // 读取 kill 脚本的输出
                    try (var reader = new java.io.BufferedReader(
                            new java.io.InputStreamReader(killProcess.getInputStream()))) {
                        String line;
                        while ((line = reader.readLine()) != null) {
                            log.info("[kill-engine] {}", line);
                        }
                    }

                    // 等待 kill 脚本完成，最多 15 秒（脚本有重试逻辑）
                    boolean finished = killProcess.waitFor(15, TimeUnit.SECONDS);
                    if (!finished) {
                        log.warn("Kill script timeout, force destroying...");
                        killProcess.destroyForcibly();
                    } else {
                        int exitCode = killProcess.exitValue();
                        log.info("Kill script finished with exit code: {}", exitCode);
                    }
                } else {
                    log.warn("Kill script not found: {}", script);
                }

                // 同时也尝试停止 Java 端记录的进程（如果仍在运行）
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
            stop();
            return start(this.lastRequest);
        }
    }

    public Map<String, Object> status() {
        synchronized (lock) {
            return buildStatus(true, null);
        }
    }

    public Map<String, Object> logs(int lines, String recordId) {
        synchronized (lock) {
            Map<String, Object> result = new HashMap<>();
            try {
                String targetId = StringUtils.hasText(recordId) ? recordId : this.lastRecordId;
                log.info("读取血缘引擎日志: lines={}, recordId={}", lines, targetId);

                Path logPath = resolveLogPath(resolveWorkDir(), targetId);
                if (!Files.exists(logPath)) {
                    result.put("success", true);
                    result.put("lines", List.of());
                    result.put("lineCount", 0);
                    result.put("logPath", logPath.toString());
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

    private void watchProcess(Process running, String recordId, Path logPath) {
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

                // Update record on completion
                if (recordId != null) {
                    updateAnalysisRecordOnCompletion(recordId, exitCode, logPath);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
            }
        }, "lineage-engine-watcher");
        watcher.setDaemon(true);
        watcher.start();
    }

    private void updateAnalysisRecordOnCompletion(String recordId, int exitCode, Path logPath) {
        try {
            LineageAnalysisRecord record = analysisRecordMapper.selectById(recordId);
            if (record != null) {
                record.setEndTime(LocalDateTime.now());
                record.setStatus(exitCode == 0 ? "SUCCESS" : "FAILED");
                if (exitCode != 0) {
                    record.setError("引擎退出码: " + exitCode);
                }

                // Parse Version ID from log
                String versionId = parseVersionIdFromLog(logPath);
                if (StringUtils.hasText(versionId)) {
                    record.setVersionId(versionId);
                }

                record.setUpdateTime(LocalDateTime.now());
                analysisRecordMapper.updateById(record);
            }
        } catch (Exception e) {
            log.error("更新分析记录失败", e);
        }
    }

    private String parseVersionIdFromLog(Path logPath) {
        if (logPath == null || !Files.exists(logPath))
            return null;
        try {
            List<String> lines = Files.readAllLines(logPath);
            // Search from bottom for "Generated version ID: "
            for (int i = lines.size() - 1; i >= 0; i--) {
                String line = lines.get(i);
                if (line.contains("Generated version ID:")) {
                    return line.substring(line.indexOf("Generated version ID:") + "Generated version ID:".length())
                            .trim();
                }
            }
        } catch (Exception e) {
            log.warn("无法解析日志中的版本 ID: {}", e.getMessage());
        }
        return null;
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

        // Add Version Consistency Info
        try {
            var wrapper = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<LineageAnalysisRecord>()
                    .eq("status", "SUCCESS")
                    .orderByDesc("start_time")
                    .last("LIMIT 1");
            LineageAnalysisRecord lastRecord = analysisRecordMapper.selectOne(wrapper);
            if (lastRecord != null) {
                var checkResult = checkVersionConsistency(lastRecord.getRepoId(), lastRecord.getRef());
                status.put("versionStatus", checkResult);
            }
        } catch (Exception e) {
            log.warn("构建状态时版本校验失败: {}", e.getMessage());
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

    private Path resolveLogPath(Path workingDir, String recordId) {
        if (StringUtils.hasText(logFile)) {
            // If explicit log file configured, use it (legacy mode or override)
            return Paths.get(logFile).toAbsolutePath().normalize();
        }
        if (StringUtils.hasText(recordId)) {
            return workingDir.resolve("logs").resolve("lineage-engine-" + recordId + ".log").toAbsolutePath()
                    .normalize();
        }
        // Fallback for no record ID (e.g. manual CLI check?)
        return workingDir.resolve("logs").resolve("lineage-engine.log").toAbsolutePath().normalize();
    }

    public Map<String, Object> checkVersionConsistency(Long repoId, String ref) {
        Map<String, Object> result = new HashMap<>();
        try {
            // 1. Get the latest successful analysis record for this repo
            var wrapper = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<LineageAnalysisRecord>()
                    .eq("repo_id", repoId)
                    .eq("status", "SUCCESS")
                    .orderByDesc("start_time")
                    .last("LIMIT 1");
            LineageAnalysisRecord lastRecord = analysisRecordMapper.selectOne(wrapper);

            if (lastRecord == null) {
                result.put("consistent", true);
                result.put("message", "尚未进行过分析");
                return result;
            }

            // 2. Get current latest commit
            var latestCommit = gitPlatformService.getLatestCommit(repoId, ref);
            if (latestCommit == null) {
                result.put("consistent", true);
                result.put("message", "无法获取当前仓库版本");
                return result;
            }

            boolean consistent = latestCommit.getSha().equalsIgnoreCase(lastRecord.getCommitSha());
            result.put("consistent", consistent);
            result.put("lastAnalysisTime", lastRecord.getEndTime());
            result.put("lastCommitSha", lastRecord.getCommitSha());
            result.put("currentCommitSha", latestCommit.getSha());
            if (!consistent) {
                result.put("message", "Git 仓库已有新提交，当前分析结果可能已过时");
            }
        } catch (Exception e) {
            log.warn("版本一致性校验失败: {}", e.getMessage());
            result.put("consistent", true); // Default to true on error to avoid false positives
            result.put("error", e.getMessage());
        }
        return result;
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
