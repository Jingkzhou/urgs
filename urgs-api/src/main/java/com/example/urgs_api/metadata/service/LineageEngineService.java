package com.example.urgs_api.metadata.service;

import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.metadata.mapper.LineageAnalysisRecordMapper;
import com.example.urgs_api.metadata.model.LineageAnalysisRecord;
import com.example.urgs_api.metadata.review.service.LineageReviewService;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;
import org.springframework.web.multipart.MultipartFile;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.time.Instant;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Executor;
import java.util.concurrent.TimeUnit;

@Slf4j
@Service
public class LineageEngineService {

    private final GitPlatformService gitPlatformService;
    private final LineageAnalysisRecordMapper analysisRecordMapper;
    private final LineageGitInputPreparer gitInputPreparer;
    private final LineageUploadInputPreparer uploadInputPreparer;
    private final LineageReviewService lineageReviewService;
    private final Executor taskExecutor;

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

    @Value("${docker.api-version:1.39}")
    private String dockerApiVersion;

    private final Object lock = new Object();
    private Process process;
    private Instant lastStartedAt;
    private Instant lastStoppedAt;
    private Integer lastExitCode;
    private String lastError;
    private StartEngineRequest lastRequest;
    private String lastRecordId;
    private boolean startInProgress;
    private String lastOperationId;

    public LineageEngineService(
            GitPlatformService gitPlatformService,
            LineageAnalysisRecordMapper analysisRecordMapper,
            LineageGitInputPreparer gitInputPreparer,
            LineageUploadInputPreparer uploadInputPreparer,
            LineageReviewService lineageReviewService,
            @Qualifier("aiTaskExecutor") Executor taskExecutor) {
        this.gitPlatformService = gitPlatformService;
        this.analysisRecordMapper = analysisRecordMapper;
        this.gitInputPreparer = gitInputPreparer;
        this.uploadInputPreparer = uploadInputPreparer;
        this.lineageReviewService = lineageReviewService;
        this.taskExecutor = taskExecutor;
    }

    public Map<String, Object> start(StartEngineRequest request) {
        StartEngineRequest normalized = normalizeRequest(request);
        log.info("[LineageEngineDiagnostics] start request normalized: {}", summarizeRequest(normalized));
        return queueStart(normalized);
    }

    public Map<String, Object> startWithUpload(List<MultipartFile> files, String user, String language,
            Boolean enableAiReview) {
        StartEngineRequest request = new StartEngineRequest();
        request.setSourceType("upload");
        request.setUser(user);
        request.setLanguage(language);
        request.setEnableAiReview(enableAiReview);
        log.info("[LineageEngineDiagnostics] startWithUpload received: fileCount={}, fileNames={}, user={}, language={}, enableAiReview={}",
                files != null ? files.size() : 0,
                files != null ? files.stream().map(MultipartFile::getOriginalFilename).toList() : List.of(),
                user,
                language,
                enableAiReview);
        try {
            synchronized (lock) {
                this.lastRequest = request;
            }
            uploadInputPreparer.stageUploads(request, files);
            return queueStart(normalizeRequest(request));
        } catch (Exception e) {
            lastError = e.getMessage();
            log.error("暂存上传文件失败", e);
            return buildStatus(false, "启动失败: " + e.getMessage(), false);
        }
    }

    private Map<String, Object> queueStart(StartEngineRequest request) {
        String operationId = newOperationId("start");
        synchronized (lock) {
            log.info("[LineageEngineDiagnostics] queueStart begin: operationId={}, request={}, running={}, startInProgress={}, lastRecordId={}, lastOperationId={}",
                    operationId, summarizeRequest(request), isRunning(), startInProgress, lastRecordId, lastOperationId);
            if (isRunning() || startInProgress) {
                log.warn("[LineageEngineDiagnostics] queueStart rejected: operationId={}, running={}, startInProgress={}",
                        operationId, isRunning(), startInProgress);
                return buildStatus(false, "引擎已在运行中", false);
            }
            this.lastRequest = request;
            this.lastExitCode = null;
            this.lastError = null;
            this.lastStoppedAt = null;
            this.startInProgress = true;
            this.lastOperationId = operationId;
            LineageAnalysisRecord record = createAnalysisRecord(request);
            this.lastRecordId = record.getId();
            log.info("[LineageEngineDiagnostics] queueStart accepted: operationId={}, recordId={}, request={}",
                    operationId, this.lastRecordId, summarizeRequest(request));
        }

        taskExecutor.execute(() -> executeStartTask(request, operationId));
        return buildStatus(true, "引擎启动任务已受理", false);
    }

    private void executeStartTask(StartEngineRequest request, String operationId) {
        long startedAt = System.currentTimeMillis();
        try {
            Path workingDir = resolveWorkDir();
            Path script = resolveScriptPath(workingDir);
            log.info("[LineageEngineDiagnostics] executeStartTask begin: operationId={}, workDir={}, script={}, request={}",
                    operationId, workingDir, script, summarizeRequest(request));
            if (!Files.exists(script)) {
                throw new IllegalStateException("启动脚本不存在: " + script);
            }

            LineageEngineInputPreparationResult inputResult = resolveInput(request, null);
            String inputPath = inputResult.inputPath();
            String repoRoot = inputResult.repoRoot();
            log.info("[LineageEngineDiagnostics] input resolved: operationId={}, inputPath={}, repoRoot={}",
                    operationId, inputPath, repoRoot);

            String recordId = this.lastRecordId;
            LineageAnalysisRecord record = StringUtils.hasText(recordId) ? analysisRecordMapper.selectById(recordId) : null;
            if (record == null) {
                record = createAnalysisRecord(request);
                recordId = record.getId();
            }
            refreshAnalysisRecord(record, request);

            Path logPath = resolveLogPath(workingDir, recordId);
            Files.createDirectories(logPath.getParent());

            List<String> command = buildStartCommand(request, inputPath, repoRoot, recordId, record);
            writeBootstrapLog(logPath, "启动任务已创建");
            writeBootstrapLog(logPath, "诊断 operationId: " + operationId);
            writeBootstrapLog(logPath, "请求摘要: " + summarizeRequest(request));
            writeBootstrapLog(logPath, "工作目录: " + workingDir);
            writeBootstrapLog(logPath, "脚本路径: " + script);
            writeBootstrapLog(logPath, "日志路径: " + logPath);
            writeBootstrapLog(logPath, "执行命令: " + String.join(" ", command));
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.directory(workingDir.toFile());
            builder.environment().put("DOCKER_API_VERSION", dockerApiVersion);
            builder.redirectErrorStream(true);
            builder.redirectOutput(ProcessBuilder.Redirect.appendTo(logPath.toFile()));

            log.info("[LineageEngineDiagnostics] process start prepared: operationId={}, recordId={}, logPath={}, command={}",
                    operationId, recordId, logPath, command);
            Process startedProcess = builder.start();
            writeBootstrapLog(logPath, "进程已启动，PID=" + startedProcess.pid());
            log.info("[LineageEngineDiagnostics] process started: operationId={}, pid={}, durationMs={}",
                    operationId, startedProcess.pid(), System.currentTimeMillis() - startedAt);

            synchronized (lock) {
                process = startedProcess;
                lastStartedAt = Instant.now();
                lastStoppedAt = null;
                lastExitCode = null;
                lastError = null;
                lastRecordId = recordId;
                startInProgress = false;
            }

            watchProcess(startedProcess, recordId, logPath, operationId);
        } catch (Exception e) {
            synchronized (lock) {
                startInProgress = false;
                lastError = e.getMessage();
                lastStoppedAt = Instant.now();
            }
            writeBootstrapFailureLog(request, e);
            log.error("[LineageEngineDiagnostics] executeStartTask failed: operationId={}, durationMs={}, request={}",
                    operationId, System.currentTimeMillis() - startedAt, summarizeRequest(request), e);
        }
    }

    private List<String> buildStartCommand(StartEngineRequest request, String inputPath, String repoRoot,
            String recordId, LineageAnalysisRecord record) {
        List<String> command = new ArrayList<>();
        command.add("bash");
        command.add(resolveScriptPath(resolveWorkDir()).toString());
        command.add("parse-sql");
        command.add("--file");
        command.add(inputPath);

        if (StringUtils.hasText(recordId)) {
            command.add("--version-id");
            command.add(recordId);
        }

        if (isGitSource(request)) {
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
        }

        if (repoRoot != null) {
            command.add("--repo-root");
            command.add(repoRoot);
        }

        if (StringUtils.hasText(request.getUser())) {
            command.add("--default-user");
            command.add(request.getUser());
        }
        if (StringUtils.hasText(request.getLanguage())) {
            command.add("--dialect");
            command.add(request.getLanguage());
        }

        command.add("--output");
        command.add("neo4j");
        return command;
    }

    private StartEngineRequest normalizeRequest(StartEngineRequest request) {
        StartEngineRequest normalized = request != null ? request : new StartEngineRequest();
        if (!StringUtils.hasText(normalized.getSourceType())) {
            if (normalized.getRepoId() != null) {
                normalized.setSourceType("git");
            } else if (StringUtils.hasText(normalized.getLocalPath())) {
                normalized.setSourceType("upload");
            }
        }
        if ("upload".equalsIgnoreCase(normalized.getSourceType())) {
            normalized.setRepoId(null);
            normalized.setRef(null);
        }
        if (normalized.getEnableAiReview() == null) {
            normalized.setEnableAiReview(true);
        }
        return normalized;
    }

    private LineageEngineInputPreparationResult resolveInput(StartEngineRequest request, List<MultipartFile> uploadedFiles)
            throws Exception {
        if ("upload".equalsIgnoreCase(request.getSourceType())) {
            return uploadInputPreparer.prepare(request, uploadedFiles);
        }
        if (isGitSource(request)) {
            return gitInputPreparer.prepare(request);
        }
        return new LineageEngineInputPreparationResult(resolveEngineArgsPath(engineArgs), null);
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

    private LineageAnalysisRecord createAnalysisRecord(StartEngineRequest request) {
        LineageAnalysisRecord record = new LineageAnalysisRecord();
        record.setRepoId(request.getRepoId());
        record.setRef(request.getRef());
        record.setPaths(request.getPaths());
        record.setDefaultUser(request.getUser());
        record.setLanguage(request.getLanguage());
        record.setAiReviewEnabled(isAiReviewEnabled(request));
        record.setStatus("PENDING");
        record.setStartTime(LocalDateTime.now());
        record.setCreateTime(LocalDateTime.now());
        record.setUpdateTime(LocalDateTime.now());

        analysisRecordMapper.insert(record);
        if (StringUtils.hasText(record.getId()) && !StringUtils.hasText(record.getVersionId())) {
            record.setVersionId(record.getId());
            analysisRecordMapper.updateById(record);
        }
        log.info("[LineageEngineDiagnostics] analysis record created: recordId={}, request={}", record.getId(), summarizeRequest(request));
        return record;
    }

    private void refreshAnalysisRecord(LineageAnalysisRecord record, StartEngineRequest request) {
        if (record == null) {
            return;
        }

        record.setRepoId(request.getRepoId());
        record.setRef(request.getRef());
        record.setPaths(request.getPaths());
        record.setDefaultUser(request.getUser());
        record.setLanguage(request.getLanguage());
        record.setAiReviewEnabled(isAiReviewEnabled(request));
        record.setStatus("RUNNING");
        record.setUpdateTime(LocalDateTime.now());

        if (isGitSource(request)) {
            try {
                var latestCommit = gitPlatformService.getLatestCommit(request.getRepoId(), request.getRef());
                if (latestCommit != null) {
                    record.setCommitSha(latestCommit.getSha());
                }
            } catch (Exception e) {
                log.warn("无法获取 Git 最新提交 SHA: {}", e.getMessage());
            }
        } else {
            record.setCommitSha(null);
        }

        analysisRecordMapper.updateById(record);
        log.info("[LineageEngineDiagnostics] analysis record refreshed: recordId={}, repoId={}, ref={}, commitSha={}, status={}",
                record.getId(), record.getRepoId(), record.getRef(), record.getCommitSha(), record.getStatus());
    }

    private void writeBootstrapLog(Path logPath, String message) {
        try {
            Files.writeString(
                    logPath,
                    LocalDateTime.now() + " [BOOT] " + message + System.lineSeparator(),
                    StandardCharsets.UTF_8,
                    java.nio.file.StandardOpenOption.CREATE,
                    java.nio.file.StandardOpenOption.APPEND);
        } catch (Exception ex) {
            log.warn("写入引导日志失败: {}", ex.getMessage());
        }
    }

    private void writeBootstrapFailureLog(StartEngineRequest request, Exception e) {
        try {
            Path workingDir = resolveWorkDir();
            Path logPath = resolveLogPath(workingDir, this.lastRecordId);
            Files.createDirectories(logPath.getParent());
            writeBootstrapLog(logPath, "启动失败: " + e.getMessage());
            writeBootstrapLog(logPath, "错误类型: " + e.getClass().getName());
            if (request != null && StringUtils.hasText(request.getSourceType())) {
                writeBootstrapLog(logPath, "sourceType=" + request.getSourceType());
            }
        } catch (Exception ex) {
            log.warn("写入启动失败日志失败: {}", ex.getMessage());
        }
    }

    public Map<String, Object> stop() {
        synchronized (lock) {
            // 注意：不再检查 isRunning()，因为 docker exec 启动的容器内进程
            // 与 Java 端的 process 对象状态是独立的。
            // bridge.sh 会执行 docker exec 后立即返回，但容器中的 Python 进程仍在运行。
            // 所以我们始终尝试执行 kill 脚本，让脚本自己判断是否有进程需要终止。
            try {
                String operationId = newOperationId("stop");
                log.info("[LineageEngineDiagnostics] stop begin: operationId={}, status={}, pid={}, recordId={}, lastOperationId={}",
                        operationId, startInProgress ? "starting" : (isRunning() ? "running" : "stopped"),
                        process != null && process.isAlive() ? process.pid() : null, lastRecordId, lastOperationId);

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
                    builder.environment().put("DOCKER_API_VERSION", dockerApiVersion);
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
                        log.warn("[LineageEngineDiagnostics] kill script timeout: operationId={}, script={}", operationId, script);
                        killProcess.destroyForcibly();
                    } else {
                        int exitCode = killProcess.exitValue();
                        log.info("[LineageEngineDiagnostics] kill script finished: operationId={}, exitCode={}", operationId, exitCode);
                    }
                } else {
                    log.warn("[LineageEngineDiagnostics] kill script not found: operationId={}, script={}", operationId, script);
                }

                // 同时也尝试停止 Java 端记录的进程（如果仍在运行）
                stopProcess(process);
                log.info("[LineageEngineDiagnostics] stop completed: operationId={}, status={}, lastExitCode={}, lastStoppedAt={}",
                        operationId, startInProgress ? "starting" : (isRunning() ? "running" : "stopped"), lastExitCode, lastStoppedAt);
                return buildStatus(true, "引擎已停止", false);
            } catch (Exception e) {
                lastError = e.getMessage();
                log.error("[LineageEngineDiagnostics] stop failed: recordId={}, lastOperationId={}", lastRecordId, lastOperationId, e);
                return buildStatus(false, "停止失败: " + e.getMessage(), false);
            }
        }
    }

    public Map<String, Object> restart() {
        synchronized (lock) {
            log.info("[LineageEngineDiagnostics] restart begin: lastRequest={}, recordId={}, pid={}",
                    summarizeRequest(this.lastRequest), lastRecordId, process != null && process.isAlive() ? process.pid() : null);
            stop();
            return start(this.lastRequest);
        }
    }

    public Map<String, Object> status() {
        synchronized (lock) {
            log.info("[LineageEngineDiagnostics] status snapshot: status={}, pid={}, recordId={}, lastExitCode={}, lastError={}, startInProgress={}, lastOperationId={}",
                    startInProgress ? "starting" : (isRunning() ? "running" : "stopped"),
                    process != null && process.isAlive() ? process.pid() : null,
                    lastRecordId, lastExitCode, lastError, startInProgress, lastOperationId);
            return buildStatus(true, null, true);
        }
    }

    public Map<String, Object> logs(int lines, String recordId) {
        synchronized (lock) {
            Map<String, Object> result = new HashMap<>();
            long startedAt = System.currentTimeMillis();
            try {
                String targetId = StringUtils.hasText(recordId) ? recordId : this.lastRecordId;
                log.info("[LineageEngineDiagnostics] logs begin: lines={}, requestedRecordId={}, targetRecordId={}, lastOperationId={}",
                        lines, recordId, targetId, lastOperationId);

                Path logPath = resolveLogPath(resolveWorkDir(), targetId);
                if (!Files.exists(logPath)) {
                    Path fallbackLogPath = resolveLatestLineageLog(resolveWorkDir());
                    if (fallbackLogPath != null) {
                        log.warn("[LineageEngineDiagnostics] logs fallback to latest file: requested={}, fallback={}", logPath, fallbackLogPath);
                        logPath = fallbackLogPath;
                    } else {
                        result.put("success", true);
                        result.put("lines", List.of());
                        result.put("lineCount", 0);
                        result.put("logPath", logPath.toString());
                        log.info("[LineageEngineDiagnostics] logs no file available: requestedRecordId={}, durationMs={}",
                                targetId, System.currentTimeMillis() - startedAt);
                        return result;
                    }
                }
                List<String> allLines = Files.readAllLines(logPath, StandardCharsets.UTF_8);
                int fromIndex = Math.max(0, allLines.size() - lines);
                List<String> tail = allLines.subList(fromIndex, allLines.size());
                result.put("success", true);
                result.put("lines", tail);
                result.put("lineCount", tail.size());
                result.put("logPath", logPath.toString());
                log.info("[LineageEngineDiagnostics] logs success: targetRecordId={}, logPath={}, requestedLines={}, returnedLines={}, totalLines={}, durationMs={}",
                        targetId, logPath, lines, tail.size(), allLines.size(), System.currentTimeMillis() - startedAt);
                return result;
            } catch (Exception e) {
                log.error("[LineageEngineDiagnostics] logs failed: requestedRecordId={}, lines={}, lastOperationId={}",
                        recordId, lines, lastOperationId, e);
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

    private Path resolveLatestLineageLog(Path workingDir) {
        Path logsDir = workingDir.resolve("logs");
        if (!Files.isDirectory(logsDir)) {
            return null;
        }
        try (var stream = Files.list(logsDir)) {
            return stream
                    .filter(Files::isRegularFile)
                    .filter(path -> path.getFileName().toString().startsWith("lineage-engine-"))
                    .filter(path -> path.getFileName().toString().endsWith(".log"))
                    .max(Comparator.comparingLong(path -> path.toFile().lastModified()))
                    .orElse(null);
        } catch (Exception e) {
            log.warn("查找最新血缘日志失败: {}", e.getMessage());
            return null;
        }
    }

    private void stopProcess(Process running) {
        if (running == null) {
            log.info("[LineageEngineDiagnostics] stopProcess skipped: running process is null");
            return;
        }
        long startedAt = System.currentTimeMillis();
        log.info("[LineageEngineDiagnostics] stopProcess begin: pid={}, timeoutSeconds={}", running.pid(), stopTimeoutSeconds);
        running.destroy();
        try {
            if (!running.waitFor(stopTimeoutSeconds, TimeUnit.SECONDS)) {
                log.warn("[LineageEngineDiagnostics] stopProcess graceful timeout: pid={}", running.pid());
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
            log.info("[LineageEngineDiagnostics] stopProcess finished: pid={}, alive={}, lastExitCode={}, durationMs={}",
                    running.pid(), running.isAlive(), lastExitCode, System.currentTimeMillis() - startedAt);
        }
    }

    private void watchProcess(Process running, String recordId, Path logPath, String operationId) {
        Thread watcher = new Thread(() -> {
            try {
                log.info("[LineageEngineDiagnostics] watcher waiting: operationId={}, pid={}, recordId={}, logPath={}",
                        operationId, running.pid(), recordId, logPath);
                int exitCode = running.waitFor();
                synchronized (lock) {
                    startInProgress = false;
                    if (process == running) {
                        lastExitCode = exitCode;
                        lastStoppedAt = Instant.now();
                        process = null;
                    }
                }
                log.info("[LineageEngineDiagnostics] watcher completed: operationId={}, pid={}, recordId={}, exitCode={}",
                        operationId, running.pid(), recordId, exitCode);

                // Update record on completion
                if (recordId != null) {
                    updateAnalysisRecordOnCompletion(recordId, exitCode, logPath);
                }
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.warn("[LineageEngineDiagnostics] watcher interrupted: operationId={}, pid={}, recordId={}",
                        operationId, running.pid(), recordId);
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
                } else if (StringUtils.hasText(recordId) && !StringUtils.hasText(record.getVersionId())) {
                    record.setVersionId(recordId);
                }

                record.setUpdateTime(LocalDateTime.now());
                analysisRecordMapper.updateById(record);
                log.info("[LineageEngineDiagnostics] analysis record completion updated: recordId={}, exitCode={}, status={}, versionId={}",
                        recordId, exitCode, record.getStatus(), record.getVersionId());
                if (exitCode == 0) {
                    lineageReviewService.scheduleTasksForAnalysis(record, false);
                }
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
            List<String> versionMarkers = List.of(
                    "Generated version ID:",
                    "Using provided version ID:",
                    "Lineage stored with version:");
            for (int i = lines.size() - 1; i >= 0; i--) {
                String line = lines.get(i);
                for (String marker : versionMarkers) {
                    if (line.contains(marker)) {
                        return line.substring(line.indexOf(marker) + marker.length()).trim();
                    }
                }
                String bootMarker = "--version-id ";
                if (line.contains(bootMarker)) {
                    String value = line.substring(line.indexOf(bootMarker) + bootMarker.length()).trim();
                    int nextSpace = value.indexOf(' ');
                    return nextSpace >= 0 ? value.substring(0, nextSpace).trim() : value;
                }
            }
        } catch (Exception e) {
            log.warn("无法解析日志中的版本 ID: {}", e.getMessage());
        }
        return null;
    }

    private Map<String, Object> buildStatus(boolean success, String message, boolean includeVersionStatus) {
        Map<String, Object> status = new HashMap<>();
        status.put("success", success);
        status.put("status", startInProgress ? "starting" : (isRunning() ? "running" : "stopped"));
        if (lastRequest != null && StringUtils.hasText(lastRequest.getSourceType())) {
            status.put("sourceType", lastRequest.getSourceType());
        }
        if (StringUtils.hasText(lastRecordId)) {
            status.put("recordId", lastRecordId);
        }
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

        boolean shouldCheckVersion = includeVersionStatus
                && !startInProgress
                && !isRunning()
                && isGitSource(lastRequest);

        if (shouldCheckVersion) {
            try {
                var wrapper = new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<LineageAnalysisRecord>()
                        .eq("repo_id", lastRequest.getRepoId())
                        .eq("status", "SUCCESS")
                        .orderByDesc("start_time")
                        .last("LIMIT 1");
                LineageAnalysisRecord lastRecord = analysisRecordMapper.selectOne(wrapper);
                if (lastRecord != null && lastRecord.getRepoId() != null) {
                    var checkResult = checkVersionConsistency(lastRecord.getRepoId(), lastRecord.getRef());
                    status.put("versionStatus", checkResult);
                }
            } catch (Exception e) {
                log.warn("构建状态时版本校验失败: {}", e.getMessage());
            }
        } else if (includeVersionStatus) {
            log.info("[LineageEngineDiagnostics] skip version check in status: sourceType={}, startInProgress={}, running={}",
                    lastRequest != null ? lastRequest.getSourceType() : null,
                    startInProgress,
                    isRunning());
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
            log.info("[LineageEngineDiagnostics] version check begin: repoId={}, ref={}", repoId, ref);
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
            log.info("[LineageEngineDiagnostics] version check completed: repoId={}, ref={}, consistent={}, lastCommitSha={}, currentCommitSha={}",
                    repoId, ref, consistent, lastRecord.getCommitSha(), latestCommit.getSha());
        } catch (Exception e) {
            log.warn("版本一致性校验失败: {}", e.getMessage());
            result.put("consistent", true); // Default to true on error to avoid false positives
            result.put("error", e.getMessage());
        }
        return result;
    }

    private String newOperationId(String action) {
        return action + "-" + UUID.randomUUID().toString().substring(0, 8);
    }

    private String summarizeRequest(StartEngineRequest request) {
        if (request == null) {
            return "null";
        }
        return "sourceType=" + request.getSourceType()
                + ", repoId=" + request.getRepoId()
                + ", ref=" + request.getRef()
                + ", pathCount=" + (request.getPaths() != null ? request.getPaths().size() : 0)
                + ", paths=" + request.getPaths()
                + ", user=" + request.getUser()
                + ", language=" + request.getLanguage()
                + ", localPath=" + request.getLocalPath()
                + ", enableAiReview=" + request.getEnableAiReview();
    }

    private boolean isAiReviewEnabled(StartEngineRequest request) {
        return request == null || !Boolean.FALSE.equals(request.getEnableAiReview());
    }

    private boolean isGitSource(StartEngineRequest request) {
        return request != null
                && "git".equalsIgnoreCase(request.getSourceType())
                && request.getRepoId() != null;
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
