package com.example.urgs_api.metadata.review.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.mapper.LineageAnalysisRecordMapper;
import com.example.urgs_api.metadata.model.LineageAnalysisRecord;
import com.example.urgs_api.metadata.review.dto.LineageReviewAIVerdict;
import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewCache;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;
import com.example.urgs_api.metadata.review.mapper.LineageReviewCacheMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewIssueMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewTaskMapper;
import com.example.urgs_api.metadata.review.service.LineageReviewAiService;
import com.example.urgs_api.metadata.review.service.LineageReviewService;
import org.neo4j.driver.Driver;
import org.neo4j.driver.Record;
import org.neo4j.driver.Session;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.concurrent.Executor;
import java.util.stream.Collectors;

@Service
public class LineageReviewServiceImpl implements LineageReviewService {

    private static final Logger log = LoggerFactory.getLogger(LineageReviewServiceImpl.class);
    private static final int TASK_BATCH_SIZE = 200;
    private static final int TASK_AI_BUDGET = 150;
    private static final int RULE_AI_BUDGET = 50;
    private static final int SQL_AUDIT_LIMIT = 100;
    private static final int SQL_AUDIT_SNIPPET_LIMIT = 12000;
    private static final int AI_REVIEW_DISABLED_BUDGET = 0;

    private final LineageAnalysisRecordMapper analysisRecordMapper;
    private final LineageReviewTaskMapper taskMapper;
    private final LineageReviewIssueMapper issueMapper;
    private final LineageReviewCacheMapper cacheMapper;
    private final LineageReviewAiService aiService;
    private final Driver neo4jDriver;
    private final Executor taskExecutor;

    public LineageReviewServiceImpl(LineageAnalysisRecordMapper analysisRecordMapper,
            LineageReviewTaskMapper taskMapper,
            LineageReviewIssueMapper issueMapper,
            LineageReviewCacheMapper cacheMapper,
            LineageReviewAiService aiService,
            Driver neo4jDriver,
            @Qualifier("aiTaskExecutor") Executor taskExecutor) {
        this.analysisRecordMapper = analysisRecordMapper;
        this.taskMapper = taskMapper;
        this.issueMapper = issueMapper;
        this.cacheMapper = cacheMapper;
        this.aiService = aiService;
        this.neo4jDriver = neo4jDriver;
        this.taskExecutor = taskExecutor;
    }

    @Override
    public List<LineageReviewTask> listTasks(String analysisRecordId, String status) {
        LambdaQueryWrapper<LineageReviewTask> query = new LambdaQueryWrapper<>();
        query.eq(StringUtils.hasText(analysisRecordId), LineageReviewTask::getAnalysisRecordId, analysisRecordId);
        query.eq(StringUtils.hasText(status), LineageReviewTask::getStatus, status);
        query.orderByDesc(LineageReviewTask::getCreateTime);
        return taskMapper.selectList(query);
    }

    @Override
    public List<LineageAnalysisRecord> listAnalysisRecords() {
        LambdaQueryWrapper<LineageAnalysisRecord> query = new LambdaQueryWrapper<>();
        query.orderByDesc(LineageAnalysisRecord::getCreateTime);
        query.last("LIMIT 100");
        return analysisRecordMapper.selectList(query);
    }

    @Override
    public Map<String, Object> triggerByAnalysisRecord(String analysisRecordId, boolean forceRerun) {
        LineageAnalysisRecord record = analysisRecordMapper.selectById(analysisRecordId);
        if (record == null) {
            return Map.of("success", false, "message", "血缘分析记录不存在");
        }
        scheduleTasksForAnalysis(record, forceRerun);
        return Map.of("success", true, "message", "血缘事后校验任务已提交");
    }

    @Override
    public void scheduleTasksForAnalysis(LineageAnalysisRecord record, boolean forceRerun) {
        if (record == null || !StringUtils.hasText(record.getId())) {
            return;
        }
        if (!"SUCCESS".equalsIgnoreCase(record.getStatus())) {
            log.info("skip lineage review scheduling because record status is not success: {}", record.getId());
            return;
        }
        String versionId = resolveReviewVersionId(record);
        if (!StringUtils.hasText(versionId)) {
            log.warn("skip lineage review scheduling because versionId is missing: {}", record.getId());
            return;
        }
        List<String> shardPaths = resolveShardPaths(record.getPaths());
        for (String shardPath : shardPaths) {
            LineageReviewTask task = upsertTask(record, shardPath, forceRerun);
            if (task == null) {
                continue;
            }
            taskExecutor.execute(() -> runTask(task.getId()));
        }
    }

    @Override
    public LineageReviewTask getTask(Long taskId) {
        return taskMapper.selectById(taskId);
    }

    @Override
    public List<LineageReviewIssue> listIssues(Long taskId, String severity, String issueType, String reviewStatus) {
        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.eq(taskId != null, LineageReviewIssue::getTaskId, taskId);
        query.eq(StringUtils.hasText(severity), LineageReviewIssue::getSeverity, severity);
        query.eq(StringUtils.hasText(issueType), LineageReviewIssue::getIssueType, issueType);
        query.eq(StringUtils.hasText(reviewStatus), LineageReviewIssue::getReviewStatus, reviewStatus);
        query.orderByDesc(LineageReviewIssue::getSeverity)
                .orderByDesc(LineageReviewIssue::getConfidence)
                .orderByDesc(LineageReviewIssue::getCreateTime);
        return issueMapper.selectList(query);
    }

    @Override
    public LineageReviewIssue getIssue(Long issueId) {
        return issueMapper.selectById(issueId);
    }

    @Override
    @Transactional
    public LineageReviewIssue decideIssue(Long issueId, Long reviewerId, LineageReviewDecisionRequest request) {
        LineageReviewIssue issue = issueMapper.selectById(issueId);
        if (issue == null) {
            throw new IllegalArgumentException("疑点不存在");
        }
        issue.setReviewStatus(StringUtils.hasText(request.getReviewStatus()) ? request.getReviewStatus() : "PENDING");
        issue.setReviewerId(reviewerId);
        issue.setReviewerNote(request.getReviewerNote());
        issue.setReviewTime(LocalDateTime.now());
        issue.setUpdateTime(LocalDateTime.now());
        issueMapper.updateById(issue);
        return issue;
    }

    @Override
    public List<Map<String, Object>> getTaskSqlPreviews(Long taskId) {
        LineageReviewTask task = taskMapper.selectById(taskId);
        if (task == null) {
            log.warn("[LineageSqlPreviewDiag] marker=sql-preview-pathfix-20260516 taskId={} taskNotFound=true", taskId);
            return Collections.emptyList();
        }
        if (!StringUtils.hasText(task.getVersionId())) {
            repairTaskVersionId(task);
            if (!StringUtils.hasText(task.getVersionId())) {
                log.warn("[LineageSqlPreviewDiag] marker=sql-preview-pathfix-20260516 taskId={} versionMissing=true pathPrefix={}",
                        taskId, task.getPathPrefix());
                return Collections.emptyList();
            }
        }
        String filterPath = normalizePathPrefix(task.getPathPrefix());
        boolean hasRepoId = task.getRepoId() != null;
        log.info("[LineageSqlPreviewDiag] marker=sql-preview-pathfix-20260516 taskId={} versionId={} repoId={} hasRepoId={} rawPathPrefix={} normalizedPathPrefix={}",
                taskId, task.getVersionId(), task.getRepoId(), hasRepoId, task.getPathPrefix(), filterPath);
        String diagnosticQuery = """
                MATCH ()-[r:DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN]->()
                WITH r,
                     [file IN coalesce(r.sourceFiles, []) WHERE file IS NOT NULL AND trim(toString(file)) <> ''] +
                     CASE
                        WHEN coalesce(r.source_file, r.sourceFile) IS NULL
                          OR trim(toString(coalesce(r.source_file, r.sourceFile))) = ''
                        THEN []
                        ELSE [toString(coalesce(r.source_file, r.sourceFile))]
                     END AS relationSourceFiles
                WHERE r.version = $versionId
                  AND ($hasRepoId = false OR r.repoId = $repoId)
                WITH r,
                     relationSourceFiles,
                     (r.snippet IS NOT NULL AND trim(r.snippet) <> '') AS hasSnippet,
                     ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                        WHERE toUpper(file) = toUpper($pathPrefix)
                           OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                           OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix))) AS pathMatched
                RETURN count(r) AS totalEdges,
                       count(CASE WHEN hasSnippet THEN 1 END) AS snippetEdges,
                       count(CASE WHEN hasSnippet AND pathMatched THEN 1 END) AS matchedSnippetEdges,
                       collect(DISTINCT relationSourceFiles)[0..5] AS sourceFileSamples,
                       collect(DISTINCT substring(coalesce(r.snippet, ''), 0, 120))[0..3] AS snippetSamples
                """;
        String query = """
                MATCH ()-[r:DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN]->()
                WITH r,
                     [file IN coalesce(r.sourceFiles, []) WHERE file IS NOT NULL AND trim(toString(file)) <> ''] +
                     CASE
                        WHEN coalesce(r.source_file, r.sourceFile) IS NULL
                          OR trim(toString(coalesce(r.source_file, r.sourceFile))) = ''
                        THEN []
                        ELSE [toString(coalesce(r.source_file, r.sourceFile))]
                     END AS relationSourceFiles
                WHERE r.version = $versionId
                  AND ($hasRepoId = false OR r.repoId = $repoId)
                  AND r.snippet IS NOT NULL
                  AND trim(r.snippet) <> ''
                  AND ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                    WHERE toUpper(file) = toUpper($pathPrefix)
                       OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                       OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix)))
                RETURN r.snippet AS snippet,
                       relationSourceFiles AS sourceFiles,
                       count(*) AS relationCount
                ORDER BY relationCount DESC
                LIMIT 20
                """;

        List<Map<String, Object>> results = new ArrayList<>();
        try (Session session = neo4jDriver.session()) {
            Record diagnostic = session.run(diagnosticQuery, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "pathPrefix", filterPath)).single();
            if (diagnostic != null) {
                log.info("[LineageSqlPreviewDiag] marker=sql-preview-pathfix-20260516 taskId={} diag={}",
                        taskId, diagnostic.asMap());
            }
            var cursor = session.run(query, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "pathPrefix", filterPath));
            while (cursor.hasNext()) {
                Record record = cursor.next();
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("snippet", record.get("snippet").isNull() ? "" : record.get("snippet").asString());
                item.put("sourceFiles", record.get("sourceFiles").asList(v -> v.asString()));
                item.put("relationCount", record.get("relationCount").asInt());
                results.add(item);
            }
        }
        log.info("[LineageSqlPreviewDiag] marker=sql-preview-pathfix-20260516 taskId={} returnedPreviews={}",
                taskId, results.size());
        return results;
    }

    @Override
    public byte[] exportTaskReport(Long taskId) {
        LineageReviewTask task = getTask(taskId);
        List<LineageReviewIssue> issues = listIssues(taskId, null, null, null);
        StringBuilder sb = new StringBuilder();
        sb.append("# SQL 血缘事后校验报告\n\n");
        if (task != null) {
            sb.append("- 分析记录: ").append(task.getAnalysisRecordId()).append("\n");
            sb.append("- 分片路径: ").append(task.getPathPrefix()).append("\n");
            sb.append("- 系统标识: ").append(task.getSystemKey()).append("\n");
            sb.append("- 状态: ").append(task.getStatus()).append("\n");
            sb.append("- 对象数: ").append(task.getObjectCount()).append("\n");
            sb.append("- 疑点数: ").append(task.getIssueCount()).append("\n\n");
        }
        for (LineageReviewIssue issue : issues.stream().limit(100).toList()) {
            sb.append("## ")
                    .append(issue.getTableName())
                    .append(issue.getColumnName() != null ? "." + issue.getColumnName() : "")
                    .append("\n");
            sb.append("- 类型: ").append(issue.getIssueType()).append("\n");
            sb.append("- 严重级别: ").append(issue.getSeverity()).append("\n");
            sb.append("- 置信度: ").append(issue.getConfidence()).append("\n");
            sb.append("- 判定: ").append(issue.getVerdict()).append("\n");
            sb.append("- 原因: ").append(issue.getReason()).append("\n");
            sb.append("- 规则命中: ").append(issue.getRuleHits()).append("\n\n");
        }
        return sb.toString().getBytes(StandardCharsets.UTF_8);
    }

    private LineageReviewTask upsertTask(LineageAnalysisRecord record, String shardPath, boolean forceRerun) {
        int tokenBudget = resolveTaskAiBudget(record);
        LambdaQueryWrapper<LineageReviewTask> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewTask::getAnalysisRecordId, record.getId())
                .eq(LineageReviewTask::getPathPrefix, shardPath)
                .last("LIMIT 1");
        LineageReviewTask existing = taskMapper.selectOne(query);
        boolean sameVersion = existing != null && Objects.equals(existing.getVersionId(), record.getVersionId());
        boolean sameAiMode = existing != null
                && Objects.equals(normalizeTokenBudget(existing.getTokenBudget()), tokenBudget);
        if (existing != null && !forceRerun && sameVersion && sameAiMode
                && !"FAILED".equalsIgnoreCase(existing.getStatus())) {
            return existing;
        }
        if (existing == null) {
            existing = new LineageReviewTask();
            existing.setAnalysisRecordId(record.getId());
            existing.setRepoId(record.getRepoId());
            existing.setVersionId(record.getVersionId());
            existing.setRef(record.getRef());
            existing.setPathPrefix(shardPath);
            existing.setSystemKey(deriveSystemKey(shardPath));
            existing.setTaskName(buildTaskName(record, shardPath));
            existing.setTokenBudget(tokenBudget);
            existing.setObjectCount(0);
            existing.setProcessedCount(0);
            existing.setIssueCount(0);
            existing.setFailedCount(0);
            existing.setAiCallCount(0);
            existing.setCacheHitCount(0);
            existing.setBatchCount(0);
            existing.setConsumedTokens(0);
            existing.setStatus("PENDING");
            existing.setCreateTime(LocalDateTime.now());
            existing.setUpdateTime(LocalDateTime.now());
            taskMapper.insert(existing);
            return existing;
        }

        existing.setVersionId(record.getVersionId());
        existing.setRepoId(record.getRepoId());
        existing.setRef(record.getRef());
        existing.setTokenBudget(tokenBudget);
        existing.setStatus("PENDING");
        existing.setLastError(null);
        existing.setStartedAt(null);
        existing.setFinishedAt(null);
        existing.setObjectCount(0);
        existing.setProcessedCount(0);
        existing.setIssueCount(0);
        existing.setFailedCount(0);
        existing.setAiCallCount(0);
        existing.setCacheHitCount(0);
        existing.setBatchCount(0);
        existing.setConsumedTokens(0);
        existing.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(existing);

        LambdaQueryWrapper<LineageReviewIssue> issueQuery = new LambdaQueryWrapper<>();
        issueQuery.eq(LineageReviewIssue::getTaskId, existing.getId());
        issueMapper.delete(issueQuery);
        return existing;
    }

    private void repairTaskVersionId(LineageReviewTask task) {
        if (task == null || StringUtils.hasText(task.getVersionId())) {
            return;
        }
        LineageAnalysisRecord record = analysisRecordMapper.selectById(task.getAnalysisRecordId());
        if (record == null) {
            return;
        }
        String versionId = resolveReviewVersionId(record);
        if (!StringUtils.hasText(versionId)) {
            return;
        }
        task.setVersionId(versionId);
        task.setRepoId(record.getRepoId());
        task.setRef(record.getRef());
        task.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(task);
        log.warn("lineage review repaired missing task versionId: taskId={}, analysisRecordId={}, versionId={}",
                task.getId(), task.getAnalysisRecordId(), versionId);
    }

    private String resolveReviewVersionId(LineageAnalysisRecord record) {
        if (StringUtils.hasText(record.getVersionId())) {
            return record.getVersionId();
        }
        if (!StringUtils.hasText(record.getId())) {
            return null;
        }
        record.setVersionId(record.getId());
        record.setUpdateTime(LocalDateTime.now());
        analysisRecordMapper.updateById(record);
        log.warn("lineage review repaired missing analysis versionId from record id: recordId={}", record.getId());
        return record.getVersionId();
    }

    private void runTask(Long taskId) {
        LineageReviewTask task = taskMapper.selectById(taskId);
        if (task == null) {
            return;
        }
        task.setStatus("RUNNING");
        task.setStartedAt(LocalDateTime.now());
        task.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(task);

        try {
            List<Map<String, Object>> objects = loadShardObjects(task);
            List<Map<String, Object>> sqlAuditObjects = loadSqlAuditObjects(task);
            task.setObjectCount(objects.size() + sqlAuditObjects.size());
            taskMapper.updateById(task);

            int processed = 0;
            int issueCount = 0;
            int failedCount = 0;
            int aiCallCount = 0;
            int cacheHits = 0;
            int batchCount = 0;

            if (!isAiReviewEnabled(task)) {
                processed = task.getObjectCount();
                batchCount = estimateBatchCount(objects, sqlAuditObjects);
                task.setStatus("COMPLETED");
                task.setFinishedAt(LocalDateTime.now());
                task.setLastError(null);
                updateTaskProgress(task, processed, issueCount, failedCount, aiCallCount, cacheHits, batchCount);
                log.info("lineage review AI disabled, taskId={}, objectCount={}, batchCount={}",
                        taskId, task.getObjectCount(), batchCount);
                return;
            }

            for (int i = 0; i < objects.size(); i += TASK_BATCH_SIZE) {
                List<Map<String, Object>> batch = objects.subList(i, Math.min(i + TASK_BATCH_SIZE, objects.size()));
                batchCount++;
                for (Map<String, Object> object : batch) {
                    try {
                        LineageReviewIssue issue = buildIssueDraft(task, object);
                        if (issue == null) {
                            processed++;
                            continue;
                        }
                        boolean useAi = shouldUseAi(issue, aiCallCount);
                        if (useAi) {
                            String cacheKey = buildCacheKey(issue);
                            issue.setCacheKey(cacheKey);
                            LineageReviewCache cache = loadCache(cacheKey);
                            if (cache != null) {
                                cacheHits++;
                                applyCache(issue, cache);
                                touchCache(cache);
                            } else {
                                aiCallCount++;
                                LineageReviewAIVerdict verdict = aiService.review(issue, buildEvidence(object, issue));
                                applyVerdict(issue, verdict);
                                saveCache(cacheKey, issue);
                            }
                        } else {
                            downgradeRuleOnlyIssue(issue);
                        }
                        issue.setTaskId(task.getId());
                        issue.setAnalysisRecordId(task.getAnalysisRecordId());
                        issue.setRepoId(task.getRepoId());
                        issue.setVersionId(task.getVersionId());
                        issue.setSystemKey(task.getSystemKey());
                        issue.setPathPrefix(task.getPathPrefix());
                        issue.setCreateTime(LocalDateTime.now());
                        issue.setUpdateTime(LocalDateTime.now());
                        issueMapper.insert(issue);
                        if (isFormalIssue(issue)) {
                            issueCount++;
                        }
                    } catch (Exception ex) {
                        failedCount++;
                        log.warn("lineage review object failed, taskId={}, object={}", taskId, object, ex);
                    } finally {
                        processed++;
                    }
                }
                updateTaskProgress(task, processed, issueCount, failedCount, aiCallCount, cacheHits, batchCount);
            }

            for (Map<String, Object> sqlAuditObject : sqlAuditObjects) {
                try {
                    if (aiCallCount >= resolveTaskAiBudget(task)) {
                        continue;
                    }
                    aiCallCount++;
                    Map<String, Object> evidence = buildSqlAuditEvidence(sqlAuditObject);
                    List<LineageReviewAIVerdict> verdicts = aiService.auditSqlLineage(evidence);
                    for (LineageReviewAIVerdict verdict : verdicts) {
                        LineageReviewIssue issue = buildSqlAuditIssue(task, sqlAuditObject, evidence, verdict);
                        if (issue == null) {
                            continue;
                        }
                        issueMapper.insert(issue);
                        if (isFormalIssue(issue)) {
                            issueCount++;
                        }
                    }
                } catch (Exception ex) {
                    failedCount++;
                    log.warn("lineage sql audit failed, taskId={}, object={}", taskId, sqlAuditObject, ex);
                } finally {
                    processed++;
                    updateTaskProgress(task, processed, issueCount, failedCount, aiCallCount, cacheHits, batchCount);
                }
            }

            task.setStatus(failedCount > 0 ? "DEGRADED" : "COMPLETED");
            task.setFinishedAt(LocalDateTime.now());
            task.setLastError(failedCount > 0 ? "部分对象处理失败" : null);
            updateTaskProgress(task, processed, issueCount, failedCount, aiCallCount, cacheHits, batchCount);
        } catch (Exception ex) {
            task.setStatus("FAILED");
            task.setLastError(ex.getMessage());
            task.setFinishedAt(LocalDateTime.now());
            task.setUpdateTime(LocalDateTime.now());
            taskMapper.updateById(task);
            log.error("lineage review task failed: {}", taskId, ex);
        }
    }

    private void updateTaskProgress(LineageReviewTask task, int processed, int issueCount,
            int failedCount, int aiCallCount, int cacheHits, int batchCount) {
        task.setProcessedCount(processed);
        task.setIssueCount(issueCount);
        task.setFailedCount(failedCount);
        task.setAiCallCount(aiCallCount);
        task.setCacheHitCount(cacheHits);
        task.setBatchCount(batchCount);
        task.setConsumedTokens(Math.min(resolveTaskAiBudget(task), aiCallCount * 12));
        task.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(task);
    }

    private List<Map<String, Object>> loadShardObjects(LineageReviewTask task) {
        if (!StringUtils.hasText(task.getVersionId())) {
            return Collections.emptyList();
        }
        String filterPath = normalizePathPrefix(task.getPathPrefix());
        boolean hasRepoId = task.getRepoId() != null;
        String query = """
                MATCH (source:Column)-[r:DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN]->(target)
                WITH source, target, r,
                     [file IN coalesce(r.sourceFiles, []) WHERE file IS NOT NULL AND trim(toString(file)) <> ''] +
                     CASE
                        WHEN coalesce(r.source_file, r.sourceFile) IS NULL
                          OR trim(toString(coalesce(r.source_file, r.sourceFile))) = ''
                        THEN []
                        ELSE [toString(coalesce(r.source_file, r.sourceFile))]
                     END AS relationSourceFiles
                WHERE r.version = $versionId
                  AND ($hasRepoId = false OR r.repoId = $repoId)
                  AND ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                    WHERE toUpper(file) = toUpper($pathPrefix)
                       OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                       OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix)))
                WITH target, collect({
                    sourceTable: source.table,
                    sourceColumn: source.name,
                    relationType: type(r),
                    snippet: coalesce(r.snippet, ''),
                    sourceFiles: relationSourceFiles
                }) AS upstreamRels
                OPTIONAL MATCH (target:Column)-[:BELONGS_TO]->(targetTable:Table)
                RETURN CASE WHEN 'Column' IN labels(target) THEN targetTable.name ELSE target.name END AS tableName,
                       CASE WHEN 'Column' IN labels(target) THEN target.name ELSE null END AS columnName,
                       labels(target) AS labels,
                       upstreamRels
                ORDER BY tableName, columnName
                """;

        List<Map<String, Object>> results = new ArrayList<>();
        try (Session session = neo4jDriver.session()) {
            var cursor = session.run(query, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "pathPrefix", filterPath));
            while (cursor.hasNext()) {
                Record record = cursor.next();
                Map<String, Object> item = new HashMap<>();
                item.put("tableName", record.get("tableName").isNull() ? null : record.get("tableName").asString());
                item.put("columnName", record.get("columnName").isNull() ? null : record.get("columnName").asString());
                item.put("labels", record.get("labels").asList(v -> v.asString()));
                item.put("upstreamRels", record.get("upstreamRels").asList(v -> v.asMap()));
                results.add(item);
            }
        }
        return results;
    }

    private List<Map<String, Object>> loadSqlAuditObjects(LineageReviewTask task) {
        if (!StringUtils.hasText(task.getVersionId())) {
            return Collections.emptyList();
        }
        String filterPath = normalizePathPrefix(task.getPathPrefix());
        boolean hasRepoId = task.getRepoId() != null;
        String query = """
                MATCH (source)-[r:DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN]->(target)
                WITH source, target, r,
                     [file IN coalesce(r.sourceFiles, []) WHERE file IS NOT NULL AND trim(toString(file)) <> ''] +
                     CASE
                        WHEN coalesce(r.source_file, r.sourceFile) IS NULL
                          OR trim(toString(coalesce(r.source_file, r.sourceFile))) = ''
                        THEN []
                        ELSE [toString(coalesce(r.source_file, r.sourceFile))]
                     END AS relationSourceFiles
                WHERE r.version = $versionId
                  AND ($hasRepoId = false OR r.repoId = $repoId)
                  AND r.snippet IS NOT NULL
                  AND trim(r.snippet) <> ''
                  AND ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                    WHERE toUpper(file) = toUpper($pathPrefix)
                       OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                       OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix)))
                WITH r.snippet AS snippet,
                     relationSourceFiles AS sourceFiles,
                     collect(DISTINCT {
                        sourceTable: CASE WHEN source:Column THEN source.table ELSE source.name END,
                        sourceColumn: CASE WHEN source:Column THEN source.name ELSE null END,
                        targetTable: CASE WHEN target:Column THEN target.table ELSE target.name END,
                        targetColumn: CASE WHEN target:Column THEN target.name ELSE null END,
                        relationType: type(r),
                        relationLevel: coalesce(r.relationLevel, ''),
                        confidence: coalesce(r.confidence, '')
                     }) AS programRelations,
                     count(*) AS relationCount
                RETURN snippet, sourceFiles, programRelations, relationCount
                ORDER BY relationCount DESC
                LIMIT $limit
                """;

        List<Map<String, Object>> results = new ArrayList<>();
        try (Session session = neo4jDriver.session()) {
            var cursor = session.run(query, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "pathPrefix", filterPath,
                    "limit", SQL_AUDIT_LIMIT));
            while (cursor.hasNext()) {
                Record record = cursor.next();
                Map<String, Object> item = new LinkedHashMap<>();
                item.put("snippet", record.get("snippet").isNull() ? "" : record.get("snippet").asString());
                item.put("sourceFiles", record.get("sourceFiles").asList(v -> v.asString()));
                item.put("programRelations", record.get("programRelations").asList(v -> v.asMap()));
                item.put("relationCount", record.get("relationCount").asInt());
                results.add(item);
            }
        }
        return results;
    }

    private Map<String, Object> buildSqlAuditEvidence(Map<String, Object> object) {
        Map<String, Object> evidence = new LinkedHashMap<>();
        evidence.put("sqlSnippet", truncateSnippet(toText(object.get("snippet"))));
        evidence.put("sourceFiles", object.getOrDefault("sourceFiles", List.of()));
        evidence.put("programRelations", object.getOrDefault("programRelations", List.of()));
        evidence.put("relationCount", object.getOrDefault("relationCount", 0));
        evidence.put("auditInstruction", "请判断 programRelations 相对于 sqlSnippet 是否有遗漏来源、错误来源、错误目标或关系类型错误。");
        return evidence;
    }

    private LineageReviewIssue buildSqlAuditIssue(LineageReviewTask task, Map<String, Object> object,
            Map<String, Object> evidence, LineageReviewAIVerdict verdict) {
        if (verdict == null || isNoIssue(verdict)) {
            return null;
        }
        String issueType = StringUtils.hasText(verdict.getIssueType()) ? verdict.getIssueType() : "NEEDS_MANUAL_REVIEW";
        String tableName = resolvePrimaryTarget(object, "targetTable");
        String columnName = resolvePrimaryTarget(object, "targetColumn");
        String snippetHash = hashOf(toText(object.get("snippet")));

        LineageReviewIssue issue = new LineageReviewIssue();
        issue.setTaskId(task.getId());
        issue.setAnalysisRecordId(task.getAnalysisRecordId());
        issue.setRepoId(task.getRepoId());
        issue.setVersionId(task.getVersionId());
        issue.setSystemKey(task.getSystemKey());
        issue.setPathPrefix(task.getPathPrefix());
        issue.setTableName(tableName);
        issue.setColumnName(columnName);
        issue.setObjectType("SQL_SNIPPET");
        issue.setIssueType(issueType);
        issue.setSeverity(StringUtils.hasText(verdict.getSeverity()) ? verdict.getSeverity() : "MEDIUM");
        issue.setConfidence(verdict.getConfidence() == null
                ? BigDecimal.valueOf(0.60).setScale(4, RoundingMode.HALF_UP)
                : verdict.getConfidence());
        issue.setVerdict(StringUtils.hasText(verdict.getVerdict()) ? verdict.getVerdict() : "NEEDS_REVIEW");
        issue.setReason(verdict.getReason());
        issue.setRuleHits(List.of("AI_SQL_LINEAGE_RECHECK", "AI_PROGRAM_LINEAGE_COMPARE"));
        issue.setSuggestedSources(verdict.getSuggestedSources() == null ? new ArrayList<>() : verdict.getSuggestedSources());
        issue.setEvidenceRefs(verdict.getEvidenceRefs() == null || verdict.getEvidenceRefs().isEmpty()
                ? buildSqlAuditEvidenceRefs(object)
                : verdict.getEvidenceRefs());
        issue.setGraphSnapshot(evidence);
        issue.setFingerprint(hashOf(task.getAnalysisRecordId(), task.getPathPrefix(), snippetHash, issueType,
                verdict.getReason(), String.valueOf(issue.getEvidenceRefs())));
        issue.setReviewStatus("PENDING");
        issue.setCreateTime(LocalDateTime.now());
        issue.setUpdateTime(LocalDateTime.now());
        return issue;
    }

    private LineageReviewIssue buildIssueDraft(LineageReviewTask task, Map<String, Object> object) {
        String tableName = toText(object.get("tableName"));
        String columnName = toText(object.get("columnName"));
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> upstreamRels = (List<Map<String, Object>>) object.getOrDefault("upstreamRels", List.of());

        Set<String> relationTypes = upstreamRels.stream()
                .map(rel -> toText(rel.get("relationType")))
                .filter(StringUtils::hasText)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Set<String> distinctSources = upstreamRels.stream()
                .map(rel -> toText(rel.get("sourceTable")) + "." + toText(rel.get("sourceColumn")))
                .collect(Collectors.toCollection(LinkedHashSet::new));
        Set<String> sourceTables = upstreamRels.stream()
                .map(rel -> toText(rel.get("sourceTable")))
                .filter(StringUtils::hasText)
                .collect(Collectors.toCollection(LinkedHashSet::new));

        List<String> ruleHits = new ArrayList<>();
        String issueType = null;
        String severity = "LOW";
        String reason = null;

        if (columnName != null && !relationTypes.contains("DERIVES_TO")) {
            issueType = "RELATION_TYPE_MISMATCH";
            severity = relationTypes.isEmpty() ? "HIGH" : "MEDIUM";
            ruleHits.add("NO_DIRECT_DERIVATION");
            reason = "字段仅存在间接依赖，缺少直接派生关系";
        }

        if (distinctSources.size() > 8) {
            issueType = issueType == null ? "OVER_CONNECTED" : issueType;
            severity = "HIGH";
            ruleHits.add("TOO_MANY_SOURCES");
            reason = "单个目标对象关联来源过多，可能存在过连或别名解析异常";
        }

        if (columnName != null && sourceTables.size() > 1 && upstreamRels.stream()
                .map(rel -> toText(rel.get("sourceColumn")))
                .filter(name -> name.equalsIgnoreCase(columnName))
                .count() > 1) {
            issueType = issueType == null ? "AMBIGUOUS_MAPPING" : issueType;
            severity = "MEDIUM";
            ruleHits.add("SAME_NAME_MULTI_TABLE");
            reason = "存在多个同名来源字段映射到同一目标字段";
        }

        long indirectOnly = upstreamRels.stream()
                .filter(rel -> !"DERIVES_TO".equalsIgnoreCase(toText(rel.get("relationType"))))
                .count();
        if (columnName == null && indirectOnly > 0 && upstreamRels.size() <= 2) {
            issueType = issueType == null ? "SPARSE_TABLE_LINEAGE" : issueType;
            severity = "MEDIUM";
            ruleHits.add("TABLE_LEVEL_RELATION_SPARSE");
            reason = "表级关系稀疏，字段级覆盖可能不足";
        }

        if (issueType == null) {
            return null;
        }

        LineageReviewIssue issue = new LineageReviewIssue();
        issue.setTableName(tableName);
        issue.setColumnName(columnName);
        issue.setObjectType(columnName == null ? "TABLE" : "COLUMN");
        issue.setIssueType(issueType);
        issue.setSeverity(severity);
        issue.setRuleHits(ruleHits);
        issue.setReason(reason);
        issue.setSuggestedSources(new ArrayList<>(distinctSources).subList(0, Math.min(5, distinctSources.size())));
        issue.setEvidenceRefs(extractEvidenceRefs(upstreamRels));
        issue.setGraphSnapshot(buildEvidence(object, issue));
        issue.setFingerprint(hashOf(task.getAnalysisRecordId(), task.getPathPrefix(), tableName, columnName, issueType, issue.getEvidenceRefs().toString()));
        issue.setReviewStatus("PENDING");
        issue.setVerdict("PENDING");
        issue.setConfidence(BigDecimal.valueOf(0.60).setScale(4, RoundingMode.HALF_UP));
        return issue;
    }

    private Map<String, Object> buildEvidence(Map<String, Object> object, LineageReviewIssue issue) {
        Map<String, Object> evidence = new LinkedHashMap<>();
        evidence.put("tableName", issue.getTableName());
        evidence.put("columnName", issue.getColumnName());
        evidence.put("issueType", issue.getIssueType());
        evidence.put("ruleHits", issue.getRuleHits());
        evidence.put("upstreamRelations", object.get("upstreamRels"));
        evidence.put("labels", object.get("labels"));
        return evidence;
    }

    private boolean shouldUseAi(LineageReviewIssue issue, int currentAiCalls) {
        if (issue == null || currentAiCalls >= RULE_AI_BUDGET) {
            return false;
        }
        return !"LOW".equalsIgnoreCase(issue.getSeverity()) || issue.getRuleHits().size() >= 2;
    }

    private int resolveTaskAiBudget(LineageAnalysisRecord record) {
        return record != null && Boolean.FALSE.equals(record.getAiReviewEnabled())
                ? AI_REVIEW_DISABLED_BUDGET
                : TASK_AI_BUDGET;
    }

    private int resolveTaskAiBudget(LineageReviewTask task) {
        return normalizeTokenBudget(task != null ? task.getTokenBudget() : null);
    }

    private int normalizeTokenBudget(Integer tokenBudget) {
        if (tokenBudget == null) {
            return TASK_AI_BUDGET;
        }
        return Math.max(tokenBudget, AI_REVIEW_DISABLED_BUDGET);
    }

    private boolean isAiReviewEnabled(LineageReviewTask task) {
        return resolveTaskAiBudget(task) > AI_REVIEW_DISABLED_BUDGET;
    }

    private int estimateBatchCount(List<Map<String, Object>> objects, List<Map<String, Object>> sqlAuditObjects) {
        int objectBatches = objects.isEmpty() ? 0 : (int) Math.ceil((double) objects.size() / TASK_BATCH_SIZE);
        return objectBatches + sqlAuditObjects.size();
    }

    private void downgradeRuleOnlyIssue(LineageReviewIssue issue) {
        issue.setVerdict("NEEDS_REVIEW");
        issue.setConfidence(BigDecimal.valueOf(0.58).setScale(4, RoundingMode.HALF_UP));
        issue.setReason(issue.getReason() + "；当前按规则结果输出，未触发 AI 复核");
    }

    private void applyVerdict(LineageReviewIssue issue, LineageReviewAIVerdict verdict) {
        issue.setIssueType(StringUtils.hasText(verdict.getIssueType()) ? verdict.getIssueType() : issue.getIssueType());
        issue.setSeverity(StringUtils.hasText(verdict.getSeverity()) ? verdict.getSeverity() : issue.getSeverity());
        issue.setConfidence(verdict.getConfidence() == null ? issue.getConfidence() : verdict.getConfidence());
        issue.setVerdict(StringUtils.hasText(verdict.getVerdict()) ? verdict.getVerdict() : "NEEDS_REVIEW");
        issue.setReason(verdict.getReason());
        if (verdict.getSuggestedSources() != null && !verdict.getSuggestedSources().isEmpty()) {
            issue.setSuggestedSources(verdict.getSuggestedSources());
        }
        if (verdict.getEvidenceRefs() != null && !verdict.getEvidenceRefs().isEmpty()) {
            issue.setEvidenceRefs(verdict.getEvidenceRefs());
        }
    }

    private boolean isFormalIssue(LineageReviewIssue issue) {
        if (issue == null) {
            return false;
        }
        if ("CONFIRMED".equalsIgnoreCase(issue.getVerdict())
                && issue.getConfidence().compareTo(BigDecimal.valueOf(0.72)) >= 0) {
            return true;
        }
        return issue.getRuleHits() != null
                && issue.getRuleHits().size() >= 2
                && "NEEDS_REVIEW".equalsIgnoreCase(issue.getVerdict());
    }

    private LineageReviewCache loadCache(String cacheKey) {
        LambdaQueryWrapper<LineageReviewCache> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewCache::getCacheKey, cacheKey).last("LIMIT 1");
        return cacheMapper.selectOne(query);
    }

    private void applyCache(LineageReviewIssue issue, LineageReviewCache cache) {
        issue.setConfidence(cache.getConfidence());
        issue.setVerdict(cache.getVerdict());
        Map<String, Object> result = cache.getResultJson();
        if (result != null) {
            issue.setReason(toText(result.get("reason")));
            issue.setSeverity(toText(result.getOrDefault("severity", issue.getSeverity())));
            issue.setIssueType(toText(result.getOrDefault("issueType", issue.getIssueType())));
            issue.setSuggestedSources(asStringList(result.get("suggestedSources")));
            issue.setEvidenceRefs(asStringList(result.get("evidenceRefs")));
        }
    }

    private void saveCache(String cacheKey, LineageReviewIssue issue) {
        LineageReviewCache cache = loadCache(cacheKey);
        if (cache == null) {
            cache = new LineageReviewCache();
            cache.setCacheKey(cacheKey);
            cache.setCreateTime(LocalDateTime.now());
            cache.setHitCount(0);
        }
        cache.setFingerprint(issue.getFingerprint());
        cache.setAiModel(aiService.resolveModelName());
        cache.setConfidence(issue.getConfidence());
        cache.setVerdict(issue.getVerdict());
        cache.setResultJson(Map.of(
                "issueType", issue.getIssueType(),
                "severity", issue.getSeverity(),
                "reason", issue.getReason(),
                "suggestedSources", issue.getSuggestedSources() == null ? List.of() : issue.getSuggestedSources(),
                "evidenceRefs", issue.getEvidenceRefs() == null ? List.of() : issue.getEvidenceRefs()));
        cache.setLastHitAt(LocalDateTime.now());
        cache.setUpdateTime(LocalDateTime.now());
        if (cache.getId() == null) {
            cacheMapper.insert(cache);
        } else {
            cacheMapper.updateById(cache);
        }
    }

    private void touchCache(LineageReviewCache cache) {
        cache.setHitCount((cache.getHitCount() == null ? 0 : cache.getHitCount()) + 1);
        cache.setLastHitAt(LocalDateTime.now());
        cache.setUpdateTime(LocalDateTime.now());
        cacheMapper.updateById(cache);
    }

    private String buildCacheKey(LineageReviewIssue issue) {
        return hashOf(issue.getIssueType(), issue.getTableName(), issue.getColumnName(), issue.getFingerprint());
    }

    private List<String> extractEvidenceRefs(List<Map<String, Object>> upstreamRels) {
        List<String> refs = new ArrayList<>();
        for (Map<String, Object> rel : upstreamRels) {
            String source = toText(rel.get("sourceTable")) + "." + toText(rel.get("sourceColumn"));
            String type = toText(rel.get("relationType"));
            String snippet = toText(rel.get("snippet"));
            refs.add(source + " [" + type + "]" + (StringUtils.hasText(snippet) ? " :: " + snippet : ""));
            if (refs.size() >= 5) {
                break;
            }
        }
        return refs;
    }

    private List<String> resolveShardPaths(List<String> paths) {
        if (paths == null || paths.isEmpty()) {
            return List.of("ALL");
        }
        return paths.stream()
                .filter(StringUtils::hasText)
                .map(this::normalizePathPrefix)
                .distinct()
                .toList();
    }

    private String normalizePathPrefix(String path) {
        if (!StringUtils.hasText(path) || ".".equals(path)) {
            return "";
        }
        String normalized = path.replace('\\', '/').trim();
        while (normalized.startsWith("./")) {
            normalized = normalized.substring(2);
        }
        return normalized;
    }

    private String deriveSystemKey(String shardPath) {
        if (!StringUtils.hasText(shardPath)) {
            return "GLOBAL";
        }
        String normalized = normalizePathPrefix(shardPath);
        if (!normalized.contains("/")) {
            return normalized.toUpperCase(Locale.ROOT);
        }
        return normalized.substring(0, normalized.indexOf('/')).toUpperCase(Locale.ROOT);
    }

    private String buildTaskName(LineageAnalysisRecord record, String shardPath) {
        String suffix = StringUtils.hasText(shardPath) ? shardPath : "GLOBAL";
        return "Lineage Review - " + record.getId() + " - " + suffix;
    }

    private boolean isNoIssue(LineageReviewAIVerdict verdict) {
        return "NO_ISSUE".equalsIgnoreCase(verdict.getIssueType())
                || "REJECTED".equalsIgnoreCase(verdict.getVerdict());
    }

    private String truncateSnippet(String snippet) {
        if (!StringUtils.hasText(snippet)) {
            return "";
        }
        if (snippet.length() <= SQL_AUDIT_SNIPPET_LIMIT) {
            return snippet;
        }
        return snippet.substring(0, SQL_AUDIT_SNIPPET_LIMIT) + "\n/* SQL snippet truncated for AI audit */";
    }

    private String resolvePrimaryTarget(Map<String, Object> object, String key) {
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> relations = (List<Map<String, Object>>) object.getOrDefault("programRelations", List.of());
        return relations.stream()
                .map(rel -> toText(rel.get(key)))
                .filter(StringUtils::hasText)
                .findFirst()
                .orElse(null);
    }

    private List<String> buildSqlAuditEvidenceRefs(Map<String, Object> object) {
        List<String> refs = new ArrayList<>();
        for (String file : asStringList(object.get("sourceFiles"))) {
            refs.add("sourceFile: " + file);
            if (refs.size() >= 3) {
                return refs;
            }
        }
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> relations = (List<Map<String, Object>>) object.getOrDefault("programRelations", List.of());
        for (Map<String, Object> rel : relations) {
            refs.add(toText(rel.get("sourceTable")) + "." + toText(rel.get("sourceColumn"))
                    + " -> " + toText(rel.get("targetTable")) + "." + toText(rel.get("targetColumn"))
                    + " [" + toText(rel.get("relationType")) + "]");
            if (refs.size() >= 5) {
                break;
            }
        }
        return refs;
    }

    private List<String> asStringList(Object value) {
        if (value instanceof List<?> list) {
            return list.stream().filter(Objects::nonNull).map(String::valueOf).toList();
        }
        return new ArrayList<>();
    }

    private String toText(Object value) {
        if (value == null) {
            return null;
        }
        String str = String.valueOf(value);
        return StringUtils.hasText(str) ? str : null;
    }

    private String hashOf(String... values) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            for (String value : values) {
                digest.update((value == null ? "" : value).getBytes(StandardCharsets.UTF_8));
                digest.update((byte) '|');
            }
            byte[] hash = digest.digest();
            StringBuilder sb = new StringBuilder();
            for (byte b : hash) {
                sb.append(String.format("%02x", b));
            }
            return sb.toString();
        } catch (Exception ex) {
            throw new IllegalStateException("生成指纹失败", ex);
        }
    }
}
