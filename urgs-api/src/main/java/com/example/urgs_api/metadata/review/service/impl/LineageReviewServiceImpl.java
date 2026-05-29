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
    private static final String AI_REVIEW_PROMPT_VERSION = "relation-type-v2";

    private final LineageAnalysisRecordMapper analysisRecordMapper;
    private final LineageReviewTaskMapper taskMapper;
    private final LineageReviewIssueMapper issueMapper;
    private final LineageReviewCacheMapper cacheMapper;
    private final LineageReviewAiService aiService;
    private final LineageReviewTaskSummaryService taskSummaryService;
    private final Driver neo4jDriver;
    private final Executor taskExecutor;

    public LineageReviewServiceImpl(LineageAnalysisRecordMapper analysisRecordMapper,
            LineageReviewTaskMapper taskMapper,
            LineageReviewIssueMapper issueMapper,
            LineageReviewCacheMapper cacheMapper,
            LineageReviewAiService aiService,
            LineageReviewTaskSummaryService taskSummaryService,
            Driver neo4jDriver,
            @Qualifier("aiTaskExecutor") Executor taskExecutor) {
        this.analysisRecordMapper = analysisRecordMapper;
        this.taskMapper = taskMapper;
        this.issueMapper = issueMapper;
        this.cacheMapper = cacheMapper;
        this.aiService = aiService;
        this.taskSummaryService = taskSummaryService;
        this.neo4jDriver = neo4jDriver;
        this.taskExecutor = taskExecutor;
    }

    @Override
    public List<LineageReviewTask> listTasks(String analysisRecordId, String status) {
        LambdaQueryWrapper<LineageReviewTask> query = new LambdaQueryWrapper<>();
        query.eq(StringUtils.hasText(analysisRecordId), LineageReviewTask::getAnalysisRecordId, analysisRecordId);
        query.eq(StringUtils.hasText(status), LineageReviewTask::getStatus, status);
        query.orderByDesc(LineageReviewTask::getCreateTime);
        List<LineageReviewTask> tasks = taskMapper.selectList(query);
        taskSummaryService.attachSummaries(tasks);
        return tasks;
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
            taskExecutor.execute(() -> runTask(task.getId(), forceRerun));
        }
    }

    @Override
    public LineageReviewTask getTask(Long taskId) {
        LineageReviewTask task = taskMapper.selectById(taskId);
        taskSummaryService.attachSummary(task);
        return task;
    }

    @Override
    public List<LineageReviewIssue> listIssues(Long taskId, String severity, String issueType, String reviewStatus) {
        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.eq(taskId != null, LineageReviewIssue::getTaskId, taskId);
        query.eq(StringUtils.hasText(severity), LineageReviewIssue::getSeverity, severity);
        query.eq(StringUtils.hasText(issueType), LineageReviewIssue::getIssueType, issueType);
        query.eq(StringUtils.hasText(reviewStatus), LineageReviewIssue::getReviewStatus, reviewStatus);
        if ("PENDING".equalsIgnoreCase(reviewStatus)) {
            query.ne(LineageReviewIssue::getVerdict, "REJECTED");
        }
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
        issue.setConfirmedProblemType(request.getConfirmedProblemType());
        issue.setConfirmedProblemDescription(request.getConfirmedProblemDescription());
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
        }
        for (Map<String, Object> auditObject : loadSqlAuditObjects(task)) {
            Map<String, Object> item = new LinkedHashMap<>();
            item.put("statementHash", auditObject.get("statementHash"));
            item.put("snippet", auditObject.get("snippet"));
            item.put("sourceFiles", auditObject.getOrDefault("sourceFiles", List.of()));
            item.put("relationCount", auditObject.getOrDefault("relationCount", 0));
            results.add(item);
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
        for (LineageReviewIssue issue : issues.stream().filter(this::isFormalIssue).limit(100).toList()) {
            sb.append("## ")
                    .append(issue.getTableName())
                    .append(issue.getColumnName() != null ? "." + issue.getColumnName() : "")
                    .append("\n");
            sb.append("- 类型: ").append(issue.getIssueType()).append("\n");
            sb.append("- 严重级别: ").append(issue.getSeverity()).append("\n");
            sb.append("- 置信度: ").append(issue.getConfidence()).append("\n");
            sb.append("- 判定: ").append(issue.getVerdict()).append("\n");
            sb.append("- 原因: ").append(issue.getReason()).append("\n");
            if (StringUtils.hasText(issue.getConfirmedProblemType())) {
                sb.append("- 人工确认问题类型: ").append(issue.getConfirmedProblemType()).append("\n");
            }
            if (StringUtils.hasText(issue.getConfirmedProblemDescription())) {
                sb.append("- 人工确认问题描述: ").append(issue.getConfirmedProblemDescription()).append("\n");
            }
            sb.append("- 规则命中: ").append(issue.getRuleHits()).append("\n");
            appendMarkdownList(sb, "证据", issue.getEvidenceRefs());
            appendMarkdownList(sb, "建议来源", issue.getSuggestedSources());
            sb.append("\n");
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
                && isActiveReviewTask(existing)) {
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

    private boolean isActiveReviewTask(LineageReviewTask task) {
        if (task == null || !StringUtils.hasText(task.getStatus())) {
            return false;
        }
        String status = task.getStatus().toUpperCase(Locale.ROOT);
        return "PENDING".equals(status) || "RUNNING".equals(status);
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

    private void runTask(Long taskId, boolean forceRerun) {
        LineageReviewTask task = taskMapper.selectById(taskId);
        if (task == null) {
            return;
        }
        task.setStatus("RUNNING");
        task.setStartedAt(LocalDateTime.now());
        task.setUpdateTime(LocalDateTime.now());
        taskMapper.updateById(task);

        try {
            boolean aiReviewEnabled = isAiReviewEnabled(task);
            List<Map<String, Object>> objects = aiReviewEnabled ? Collections.emptyList() : loadShardObjects(task);
            List<Map<String, Object>> sqlAuditObjects = aiReviewEnabled ? loadSqlAuditObjects(task) : Collections.emptyList();
            task.setObjectCount(objects.size() + sqlAuditObjects.size());
            taskMapper.updateById(task);

            int processed = 0;
            int issueCount = 0;
            int failedCount = 0;
            int aiCallCount = 0;
            int cacheHits = 0;
            int batchCount = 0;

            if (!aiReviewEnabled) {
                log.info("lineage review AI disabled, keep rule-only issue generation, taskId={}, objectCount={}",
                        taskId, task.getObjectCount());
            } else {
                log.info("lineage review AI enabled, skip rule-first drafts and audit parsed lineage directly, taskId={}, sqlAuditObjectCount={}",
                        taskId, sqlAuditObjects.size());
            }

            for (int i = 0; i < objects.size(); i += TASK_BATCH_SIZE) {
                List<Map<String, Object>> batch = objects.subList(i, Math.min(i + TASK_BATCH_SIZE, objects.size()));
                batchCount++;
                for (Map<String, Object> object : batch) {
                    try {
                        LineageReviewIssue issue = buildIssueDraft(task, object);
                        if (issue == null) {
                            continue;
                        }
                        boolean useAi = aiReviewEnabled && shouldUseAi(issue, aiCallCount);
                        if (useAi) {
                            String cacheKey = buildCacheKey(issue);
                            issue.setCacheKey(cacheKey);
                            LineageReviewCache cache = forceRerun ? null : loadCache(cacheKey);
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
                        applyAutomaticReviewStatus(issue);
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
                    if (!aiReviewEnabled) {
                        continue;
                    }
                    if (aiCallCount >= resolveTaskAiBudget(task)) {
                        continue;
                    }
                    aiCallCount++;
                    Map<String, Object> evidence = buildSqlAuditEvidence(task, sqlAuditObject);
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
        int objectCount = task.getObjectCount() == null ? 0 : task.getObjectCount();
        task.setProcessedCount(objectCount > 0 ? Math.min(processed, objectCount) : processed);
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
                    confidence: coalesce(r.confidence, ''),
                    ambiguityCode: coalesce(r.ambiguityCode, ''),
                    validationNote: coalesce(r.validationNote, ''),
                    metadataMatched: r.metadataMatched,
                    metadataPackHash: coalesce(r.metadataPackHash, ''),
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
                  AND ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                    WHERE toUpper(file) = toUpper($pathPrefix)
                       OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                       OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix)))
                WITH source, target, r, relationSourceFiles,
                     CASE
                        WHEN size(coalesce(r.statementHashes, [])) > 0 THEN coalesce(r.statementHashes, [])
                        ELSE [coalesce(r.statementHash, '')]
                     END AS statementHashes,
                     coalesce(r.snippets, []) AS snippets,
                     coalesce(r.normalizedSnippets, []) AS normalizedSnippets
                UNWIND range(0, size(statementHashes) - 1) AS statementIndex
                WITH source, target, r, relationSourceFiles,
                     statementHashes[statementIndex] AS statementHash,
                     CASE
                        WHEN statementIndex < size(snippets) THEN snippets[statementIndex]
                        ELSE coalesce(r.snippet, '')
                     END AS snippet,
                     CASE
                        WHEN statementIndex < size(normalizedSnippets) THEN normalizedSnippets[statementIndex]
                        ELSE coalesce(r.normalizedSnippet, '')
                     END AS normalizedSnippet
                WHERE trim(coalesce(statementHash, '')) <> ''
                   OR trim(coalesce(snippet, '')) <> ''
                RETURN coalesce(statementHash, '') AS statementHash,
                       coalesce(normalizedSnippet, '') AS normalizedSnippet,
                       coalesce(snippet, '') AS snippet,
                       relationSourceFiles AS sourceFiles,
                       CASE WHEN source:Column THEN source.table ELSE source.name END AS sourceTable,
                       CASE WHEN source:Column THEN source.name ELSE null END AS sourceColumn,
                       CASE WHEN target:Column THEN target.table ELSE target.name END AS targetTable,
                       CASE WHEN target:Column THEN target.name ELSE null END AS targetColumn,
                       type(r) AS relationType,
                       coalesce(r.relationLevel, '') AS relationLevel,
                       coalesce(r.confidence, '') AS confidence,
                       coalesce(r.ambiguityCode, '') AS ambiguityCode,
                       coalesce(r.validationNote, '') AS validationNote,
                       coalesce(r.sourceColumns, []) AS sourceColumns,
                       coalesce(r.targetColumns, []) AS targetColumns
                ORDER BY statementHash, snippet, relationType, sourceTable, sourceColumn
                LIMIT $rowLimit
                """;

        Map<String, Map<String, Object>> grouped = new LinkedHashMap<>();
        try (Session session = neo4jDriver.session()) {
            var cursor = session.run(query, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "pathPrefix", filterPath,
                    "rowLimit", SQL_AUDIT_LIMIT * 200));
            while (cursor.hasNext()) {
                Record record = cursor.next();
                String statementHash = record.get("statementHash").asString("");
                String normalizedSnippet = record.get("normalizedSnippet").asString("");
                String snippet = record.get("snippet").asString("");
                String normalizedForFallback = StringUtils.hasText(normalizedSnippet)
                        ? normalizedSnippet
                        : normalizeSqlForAudit(snippet);
                String statementKey = StringUtils.hasText(statementHash)
                        ? statementHash
                        : hashOf(normalizedForFallback);

                Map<String, Object> item = grouped.computeIfAbsent(statementKey, key -> {
                    Map<String, Object> created = new LinkedHashMap<>();
                    created.put("statementHash", StringUtils.hasText(statementHash) ? statementHash : key);
                    created.put("normalizedSnippet", normalizedForFallback);
                    created.put("snippet", snippet);
                    created.put("sourceFiles", new ArrayList<String>());
                    created.put("programRelations", new ArrayList<Map<String, Object>>());
                    created.put("relationCount", 0);
                    created.put("_relationKeys", new LinkedHashSet<String>());
                    return created;
                });

                if (!StringUtils.hasText(toText(item.get("snippet"))) && StringUtils.hasText(snippet)) {
                    item.put("snippet", snippet);
                }
                if (!StringUtils.hasText(toText(item.get("normalizedSnippet"))) && StringUtils.hasText(normalizedForFallback)) {
                    item.put("normalizedSnippet", normalizedForFallback);
                }

                @SuppressWarnings("unchecked")
                List<String> sourceFiles = (List<String>) item.get("sourceFiles");
                List<String> rowSourceFiles = record.get("sourceFiles").asList(v -> v.isNull() ? "" : v.asString());
                for (String file : rowSourceFiles) {
                    if (StringUtils.hasText(file) && !sourceFiles.contains(file)) {
                        sourceFiles.add(file);
                    }
                }

                Map<String, Object> relation = new LinkedHashMap<>();
                relation.put("statementHash", item.get("statementHash"));
                relation.put("sourceFiles", rowSourceFiles);
                relation.put("sourceTable", record.get("sourceTable").isNull() ? null : record.get("sourceTable").asString());
                relation.put("sourceColumn", record.get("sourceColumn").isNull() ? null : record.get("sourceColumn").asString());
                relation.put("targetTable", record.get("targetTable").isNull() ? null : record.get("targetTable").asString());
                relation.put("targetColumn", record.get("targetColumn").isNull() ? null : record.get("targetColumn").asString());
                relation.put("relationType", record.get("relationType").asString(""));
                relation.put("relationLevel", record.get("relationLevel").asString(""));
                relation.put("confidence", record.get("confidence").asString(""));
                relation.put("ambiguityCode", record.get("ambiguityCode").asString(""));
                relation.put("validationNote", record.get("validationNote").asString(""));
                relation.put("sourceColumns", record.get("sourceColumns").asList(v -> v.isNull() ? "" : v.asString()));
                relation.put("targetColumns", record.get("targetColumns").asList(v -> v.isNull() ? "" : v.asString()));

                addProgramRelation(item, relation);
                for (Map<String, Object> expandedRelation : expandTableEvidenceRelation(relation)) {
                    addProgramRelation(item, expandedRelation);
                }
            }
        }

        List<Map<String, Object>> results = new ArrayList<>();
        for (Map<String, Object> item : grouped.values()) {
            item.remove("_relationKeys");
            results.add(item);
        }
        results.sort((left, right) -> Integer.compare(
                ((Number) right.getOrDefault("relationCount", 0)).intValue(),
                ((Number) left.getOrDefault("relationCount", 0)).intValue()));
        if (results.size() > SQL_AUDIT_LIMIT) {
            return new ArrayList<>(results.subList(0, SQL_AUDIT_LIMIT));
        }
        return results;
    }

    private void addProgramRelation(Map<String, Object> item, Map<String, Object> relation) {
        String relationKey = String.join("|",
                Objects.toString(relation.get("sourceTable"), ""),
                Objects.toString(relation.get("sourceColumn"), ""),
                Objects.toString(relation.get("targetTable"), ""),
                Objects.toString(relation.get("targetColumn"), ""),
                Objects.toString(relation.get("relationType"), ""),
                Objects.toString(relation.get("relationLevel"), ""));
        @SuppressWarnings("unchecked")
        Set<String> relationKeys = (Set<String>) item.get("_relationKeys");
        if (!relationKeys.add(relationKey)) {
            return;
        }
        @SuppressWarnings("unchecked")
        List<Map<String, Object>> programRelations = (List<Map<String, Object>>) item.get("programRelations");
        programRelations.add(relation);
        item.put("relationCount", ((Integer) item.get("relationCount")) + 1);
    }

    private List<Map<String, Object>> expandTableEvidenceRelation(Map<String, Object> relation) {
        if (StringUtils.hasText(toText(relation.get("sourceColumn")))
                || StringUtils.hasText(toText(relation.get("targetColumn")))) {
            return Collections.emptyList();
        }
        List<String> sourceColumns = normalizeStringList(relation.get("sourceColumns"));
        List<String> targetColumns = normalizeStringList(relation.get("targetColumns"));
        if (sourceColumns.isEmpty() || targetColumns.isEmpty()) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> expanded = new ArrayList<>();
        Set<String> usedPairs = new LinkedHashSet<>();
        for (String sourceColumn : sourceColumns) {
            for (String targetColumn : targetColumns) {
                if (!sourceColumn.equalsIgnoreCase(targetColumn)) {
                    continue;
                }
                addExpandedFieldRelation(relation, sourceColumn, targetColumn, expanded, usedPairs);
            }
        }
        if (expanded.isEmpty() && sourceColumns.size() == targetColumns.size()) {
            for (int i = 0; i < sourceColumns.size(); i++) {
                addExpandedFieldRelation(relation, sourceColumns.get(i), targetColumns.get(i), expanded, usedPairs);
            }
        }
        return expanded;
    }

    private void addExpandedFieldRelation(Map<String, Object> relation, String sourceColumn, String targetColumn,
            List<Map<String, Object>> expanded, Set<String> usedPairs) {
        if (!StringUtils.hasText(sourceColumn) || !StringUtils.hasText(targetColumn)) {
            return;
        }
        String key = sourceColumn.toUpperCase(Locale.ROOT) + "->" + targetColumn.toUpperCase(Locale.ROOT);
        if (!usedPairs.add(key)) {
            return;
        }
        Map<String, Object> fieldRelation = new LinkedHashMap<>(relation);
        fieldRelation.put("sourceColumn", sourceColumn);
        fieldRelation.put("targetColumn", targetColumn);
        fieldRelation.put("relationLevel", "field_evidence_from_table");
        fieldRelation.put("evidenceDerivedFrom", "table_relation_columns");
        expanded.add(fieldRelation);
    }

    private Map<String, Object> buildSqlAuditEvidence(LineageReviewTask task, Map<String, Object> object) {
        List<Map<String, Object>> graphFieldRelations = loadGraphFieldRelationsForAudit(task, object);
        Map<String, Object> evidence = new LinkedHashMap<>();
        evidence.put("statementHash", object.get("statementHash"));
        evidence.put("normalizedSnippet", object.get("normalizedSnippet"));
        evidence.put("sqlSnippet", truncateSnippet(toText(object.get("snippet"))));
        evidence.put("sourceFiles", object.getOrDefault("sourceFiles", List.of()));
        evidence.put("programRelations", object.getOrDefault("programRelations", List.of()));
        evidence.put("graphFieldRelations", graphFieldRelations);
        evidence.put("relationsByType", groupRelationsByType(object.get("programRelations")));
        evidence.put("relationTypeDescriptions", relationTypeDescriptions());
        evidence.put("relationCount", object.getOrDefault("relationCount", 0));
        evidence.put("auditInstruction",
                "请判断同一 statementHash 下的全部 programRelations 相对于 sqlSnippet 是否有遗漏来源、错误来源、错误目标或关系类型错误。"
                        + "必须按 relationTypeDescriptions 理解每种关系类型。"
                        + "graphFieldRelations 是同版本、同源文件、同目标表下已经写入图谱的字段级关系，前台血缘查询也会使用这些关系。"
                        + "如果 suggested source 到 target 的字段关系已存在于 graphFieldRelations，不得输出 MISSING_SOURCE。"
                        + "CASE_WHEN 表示 CASE/IF 条件分支依赖，不是目标字段值的直接来源；"
                        + "如果目标字段由 THEN/ELSE 常量或分类值生成，不得因缺少 DERIVES_TO 判定为疑点。"
                        + "如果某个表已经以 JOINS/FILTERS/CASE_WHEN 等影响关系存在，不要把它判定为来源遗漏。");
        return evidence;
    }

    private List<Map<String, Object>> loadGraphFieldRelationsForAudit(LineageReviewTask task, Map<String, Object> object) {
        if (task == null || !StringUtils.hasText(task.getVersionId())) {
            return Collections.emptyList();
        }
        String targetTable = resolvePrimaryTarget(object, "targetTable");
        if (!StringUtils.hasText(targetTable)) {
            return Collections.emptyList();
        }
        List<String> sourceFiles = asStringList(object.get("sourceFiles")).stream()
                .filter(StringUtils::hasText)
                .distinct()
                .toList();
        String filterPath = normalizePathPrefix(task.getPathPrefix());
        boolean hasSourceFiles = !sourceFiles.isEmpty();
        boolean hasRepoId = task.getRepoId() != null;
        String query = """
                MATCH (source:Column)-[r:DERIVES_TO|FILTERS|JOINS|GROUPS|ORDERS|CALLS|REFERENCES|CASE_WHEN]->(target:Column)
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
                  AND toUpper(coalesce(target.table, '')) = toUpper($targetTable)
                  AND (
                    ($hasSourceFiles = true AND ANY(file IN relationSourceFiles WHERE file IN $sourceFiles))
                    OR ($hasSourceFiles = false AND ($pathPrefix = '' OR ANY(file IN relationSourceFiles
                      WHERE toUpper(file) = toUpper($pathPrefix)
                         OR toUpper(file) STARTS WITH toUpper($pathPrefix)
                         OR toUpper(file) ENDS WITH '/' + toUpper($pathPrefix))))
                  )
                RETURN source.table AS sourceTable,
                       source.name AS sourceColumn,
                       target.table AS targetTable,
                       target.name AS targetColumn,
                       type(r) AS relationType,
                       coalesce(r.relationLevel, '') AS relationLevel,
                       coalesce(r.confidence, '') AS confidence,
                       coalesce(r.ambiguityCode, '') AS ambiguityCode,
                       coalesce(r.validationNote, '') AS validationNote,
                       coalesce(r.statementHash, '') AS statementHash,
                       relationSourceFiles AS sourceFiles
                ORDER BY relationType, sourceTable, sourceColumn, targetColumn
                LIMIT 500
                """;

        List<Map<String, Object>> relations = new ArrayList<>();
        try (Session session = neo4jDriver.session()) {
            var cursor = session.run(query, Map.of(
                    "repoId", task.getRepoId() == null ? "" : String.valueOf(task.getRepoId()),
                    "hasRepoId", hasRepoId,
                    "versionId", task.getVersionId(),
                    "targetTable", targetTable,
                    "sourceFiles", sourceFiles,
                    "hasSourceFiles", hasSourceFiles,
                    "pathPrefix", filterPath));
            Set<String> seen = new LinkedHashSet<>();
            while (cursor.hasNext()) {
                Record record = cursor.next();
                Map<String, Object> relation = new LinkedHashMap<>();
                relation.put("sourceTable", record.get("sourceTable").asString(""));
                relation.put("sourceColumn", record.get("sourceColumn").asString(""));
                relation.put("targetTable", record.get("targetTable").asString(""));
                relation.put("targetColumn", record.get("targetColumn").asString(""));
                relation.put("relationType", record.get("relationType").asString(""));
                relation.put("relationLevel", record.get("relationLevel").asString(""));
                relation.put("confidence", record.get("confidence").asString(""));
                relation.put("ambiguityCode", record.get("ambiguityCode").asString(""));
                relation.put("validationNote", record.get("validationNote").asString(""));
                relation.put("statementHash", record.get("statementHash").asString(""));
                relation.put("sourceFiles", record.get("sourceFiles").asList(v -> v.isNull() ? "" : v.asString()));
                relation.put("evidenceScope", "version_source_file_graph");
                String key = String.join("|",
                        Objects.toString(relation.get("sourceTable"), ""),
                        Objects.toString(relation.get("sourceColumn"), ""),
                        Objects.toString(relation.get("targetTable"), ""),
                        Objects.toString(relation.get("targetColumn"), ""),
                        Objects.toString(relation.get("relationType"), ""));
                if (seen.add(key)) {
                    relations.add(relation);
                }
            }
        } catch (Exception ex) {
            log.warn("[LineageSqlAudit] failed to load graph field relations taskId={} targetTable={} reason={}",
                    task.getId(), targetTable, ex.getMessage());
            return Collections.emptyList();
        }
        return relations;
    }

    private LineageReviewIssue buildSqlAuditIssue(LineageReviewTask task, Map<String, Object> object,
            Map<String, Object> evidence, LineageReviewAIVerdict verdict) {
        if (verdict == null || isNoIssue(verdict)) {
            return null;
        }
        String issueType = StringUtils.hasText(verdict.getIssueType()) ? verdict.getIssueType() : "NEEDS_MANUAL_REVIEW";
        if (!hasVerdictEvidence(verdict)) {
            log.warn("[LineageSqlAudit] drop issue without evidence taskId={} issueType={} target={}.{}",
                    task.getId(), issueType, verdict.getTargetTable(), verdict.getTargetColumn());
            return null;
        }
        String tableName = normalizeAuditTarget(verdict.getTargetTable());
        String columnName = normalizeAuditTarget(verdict.getTargetColumn());
        if (!StringUtils.hasText(tableName)) {
            log.warn("[LineageSqlAudit] drop issue without target table taskId={} issueType={} reason={}",
                    task.getId(), issueType, verdict.getReason());
            return null;
        }
        if (!isPreciseSqlAuditVerdict(issueType, columnName, verdict)) {
            log.warn("[LineageSqlAudit] drop imprecise issue taskId={} issueType={} target={}.{} reason={}",
                    task.getId(), issueType, tableName, columnName, verdict.getReason());
            return null;
        }
        if (isAlreadyCoveredMissingSource(issueType, tableName, columnName, evidence, verdict)) {
            log.info("[LineageSqlAudit] drop covered missing-source issue taskId={} target={}.{} suggestedSources={}",
                    task.getId(), tableName, columnName, verdict.getSuggestedSources());
            return null;
        }
        String statementHash = toText(object.get("statementHash"));
        String snippetHash = StringUtils.hasText(statementHash) ? statementHash : hashOf(toText(object.get("snippet")));

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
        issue.setReason(buildPreciseSqlAuditReason(issueType, tableName, columnName, verdict));
        issue.setRuleHits(List.of("AI_SQL_LINEAGE_RECHECK", "AI_PROGRAM_LINEAGE_COMPARE"));
        issue.setSuggestedSources(verdict.getSuggestedSources() == null ? new ArrayList<>() : verdict.getSuggestedSources());
        issue.setEvidenceRefs(new ArrayList<>(verdict.getEvidenceRefs()));
        issue.setGraphSnapshot(evidence);
        issue.setFingerprint(hashOf(task.getAnalysisRecordId(), task.getPathPrefix(), snippetHash, issueType,
                verdict.getReason(), String.valueOf(issue.getEvidenceRefs())));
        issue.setReviewStatus("PENDING");
        issue.setCreateTime(LocalDateTime.now());
        issue.setUpdateTime(LocalDateTime.now());
        return issue;
    }

    private boolean isPreciseSqlAuditVerdict(String issueType, String columnName, LineageReviewAIVerdict verdict) {
        if (!requiresColumnLevelAudit(issueType)) {
            return true;
        }
        if (!StringUtils.hasText(columnName)) {
            return false;
        }
        boolean hasColumnSource = verdict.getSuggestedSources() != null
                && verdict.getSuggestedSources().stream()
                        .map(this::toText)
                        .anyMatch(this::looksLikeQualifiedColumn);
        boolean hasColumnEvidence = verdict.getEvidenceRefs() != null
                && verdict.getEvidenceRefs().stream()
                        .map(this::toText)
                        .anyMatch(ref -> ref.toUpperCase(Locale.ROOT).contains(columnName.toUpperCase(Locale.ROOT)));
        return hasColumnSource || hasColumnEvidence;
    }

    private boolean requiresColumnLevelAudit(String issueType) {
        return "MISSING_SOURCE".equalsIgnoreCase(issueType)
                || "WRONG_SOURCE".equalsIgnoreCase(issueType)
                || "WRONG_TARGET".equalsIgnoreCase(issueType)
                || "WRONG_RELATION_TYPE".equalsIgnoreCase(issueType)
                || "UNCERTAIN_MAPPING".equalsIgnoreCase(issueType);
    }

    private boolean looksLikeQualifiedColumn(String value) {
        if (!StringUtils.hasText(value)) {
            return false;
        }
        String normalized = value.trim();
        int firstDot = normalized.indexOf('.');
        int lastDot = normalized.lastIndexOf('.');
        return firstDot > 0 && lastDot > firstDot && lastDot < normalized.length() - 1;
    }

    private boolean isAlreadyCoveredMissingSource(String issueType, String tableName, String columnName,
            Map<String, Object> evidence, LineageReviewAIVerdict verdict) {
        if (!"MISSING_SOURCE".equalsIgnoreCase(issueType)
                || !StringUtils.hasText(tableName)
                || !StringUtils.hasText(columnName)
                || verdict.getSuggestedSources() == null
                || verdict.getSuggestedSources().isEmpty()) {
            return false;
        }
        List<Map<String, Object>> relations = new ArrayList<>(asRelationMapList(evidence.get("programRelations")));
        relations.addAll(asRelationMapList(evidence.get("graphFieldRelations")));
        if (relations.isEmpty()) {
            return false;
        }
        List<Map<String, String>> suggestedSources = verdict.getSuggestedSources().stream()
                .map(this::parseQualifiedColumn)
                .filter(Objects::nonNull)
                .toList();
        if (suggestedSources.isEmpty()) {
            return false;
        }
        return suggestedSources.stream()
                .allMatch(source -> hasFieldRelation(relations, source.get("table"), source.get("column"), tableName, columnName));
    }

    private List<Map<String, Object>> asRelationMapList(Object value) {
        if (!(value instanceof List<?> list)) {
            return Collections.emptyList();
        }
        List<Map<String, Object>> relations = new ArrayList<>();
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> rawMap)) {
                continue;
            }
            Map<String, Object> relation = new LinkedHashMap<>();
            rawMap.forEach((key, mapValue) -> {
                if (key != null) {
                    relation.put(String.valueOf(key), mapValue);
                }
            });
            relations.add(relation);
        }
        return relations;
    }

    private Map<String, String> parseQualifiedColumn(String value) {
        if (!looksLikeQualifiedColumn(value)) {
            return null;
        }
        String normalized = value.trim();
        int lastDot = normalized.lastIndexOf('.');
        Map<String, String> result = new HashMap<>();
        result.put("table", normalized.substring(0, lastDot));
        result.put("column", normalized.substring(lastDot + 1));
        return result;
    }

    private boolean hasFieldRelation(List<Map<String, Object>> relations, String sourceTable, String sourceColumn,
            String targetTable, String targetColumn) {
        return relations.stream().anyMatch(rel -> {
            String relationType = toText(rel.get("relationType"));
            if (!"DERIVES_TO".equalsIgnoreCase(relationType) && !"CASE_WHEN".equalsIgnoreCase(relationType)) {
                return false;
            }
            if (!sameQualifiedName(sourceTable, toText(rel.get("sourceTable")))
                    || !sameQualifiedName(targetTable, toText(rel.get("targetTable")))) {
                return false;
            }
            boolean directColumnMatched = sourceColumn.equalsIgnoreCase(toText(rel.get("sourceColumn")))
                    && targetColumn.equalsIgnoreCase(toText(rel.get("targetColumn")));
            if (directColumnMatched) {
                return true;
            }
            List<String> sourceColumns = normalizeStringList(rel.get("sourceColumns"));
            List<String> targetColumns = normalizeStringList(rel.get("targetColumns"));
            return columnArraysContainRelation(sourceColumns, targetColumns, sourceColumn, targetColumn);
        });
    }

    private boolean columnArraysContainRelation(List<String> sourceColumns, List<String> targetColumns,
            String sourceColumn, String targetColumn) {
        if (sourceColumns.isEmpty() || targetColumns.isEmpty()) {
            return false;
        }
        if (sourceColumn.equalsIgnoreCase(targetColumn)
                && sourceColumns.stream().anyMatch(sourceColumn::equalsIgnoreCase)
                && targetColumns.stream().anyMatch(targetColumn::equalsIgnoreCase)) {
            return true;
        }
        if (sourceColumns.size() != targetColumns.size()) {
            return false;
        }
        for (int i = 0; i < sourceColumns.size(); i++) {
            if (sourceColumn.equalsIgnoreCase(sourceColumns.get(i))
                    && targetColumn.equalsIgnoreCase(targetColumns.get(i))) {
                return true;
            }
        }
        return false;
    }

    private boolean sameQualifiedName(String left, String right) {
        if (!StringUtils.hasText(left) || !StringUtils.hasText(right)) {
            return false;
        }
        return left.equalsIgnoreCase(right)
                || left.toUpperCase(Locale.ROOT).endsWith("." + right.toUpperCase(Locale.ROOT))
                || right.toUpperCase(Locale.ROOT).endsWith("." + left.toUpperCase(Locale.ROOT));
    }

    private String buildPreciseSqlAuditReason(String issueType, String tableName, String columnName,
            LineageReviewAIVerdict verdict) {
        String target = StringUtils.hasText(columnName) ? tableName + "." + columnName : tableName;
        String sourceSummary = verdict.getSuggestedSources() == null || verdict.getSuggestedSources().isEmpty()
                ? "未给出字段级建议来源"
                : String.join(", ", verdict.getSuggestedSources());
        String evidenceSummary = verdict.getEvidenceRefs() == null || verdict.getEvidenceRefs().isEmpty()
                ? "未给出字段级证据"
                : String.join("；", verdict.getEvidenceRefs());
        return "目标字段: " + target
                + "；疑点类型: " + issueType
                + "；应有来源: " + sourceSummary
                + "；字段级证据: " + evidenceSummary
                + "；判断说明: " + toText(verdict.getReason());
    }

    private boolean hasVerdictEvidence(LineageReviewAIVerdict verdict) {
        return verdict.getEvidenceRefs() != null
                && verdict.getEvidenceRefs().stream().anyMatch(StringUtils::hasText);
    }

    private String normalizeAuditTarget(String value) {
        if (!StringUtils.hasText(value) || "null".equalsIgnoreCase(value.trim())) {
            return null;
        }
        return value.trim();
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
        Set<String> ambiguityCodes = upstreamRels.stream()
                .map(rel -> toText(rel.get("ambiguityCode")))
                .filter(StringUtils::hasText)
                .collect(Collectors.toCollection(LinkedHashSet::new));
        boolean hasLowConfidence = upstreamRels.stream()
                .map(rel -> toText(rel.get("confidence")))
                .anyMatch(value -> "LOW".equalsIgnoreCase(value));

        List<String> ruleHits = new ArrayList<>();
        String issueType = null;
        String severity = "LOW";
        String reason = null;

        if (columnName != null && !relationTypes.contains("DERIVES_TO") && !relationTypes.contains("CASE_WHEN")) {
            issueType = "RELATION_TYPE_MISMATCH";
            severity = relationTypes.isEmpty() ? "HIGH" : "MEDIUM";
            ruleHits.add("NO_DIRECT_DERIVATION");
            reason = "字段仅存在间接依赖，缺少直接派生关系";
        }

        if (!ambiguityCodes.isEmpty()) {
            issueType = issueType == null ? "METADATA_AMBIGUITY" : issueType;
            severity = "HIGH";
            ruleHits.addAll(ambiguityCodes);
            reason = reason == null
                    ? "物理模型校验发现字段归属歧义或字段缺失: " + String.join(", ", ambiguityCodes)
                    : reason + "；物理模型疑点: " + String.join(", ", ambiguityCodes);
        } else if (hasLowConfidence) {
            issueType = issueType == null ? "LOW_CONFIDENCE_LINEAGE" : issueType;
            severity = "MEDIUM";
            ruleHits.add("LOW_CONFIDENCE");
            reason = reason == null ? "血缘解析置信度较低，需要人工复核" : reason + "；存在低置信血缘";
        }

        boolean tooManyColumnSources = columnName != null && distinctSources.size() > 8;
        boolean tooManyTableSources = columnName == null && sourceTables.size() > 5 && distinctSources.size() > 16;
        if (tooManyColumnSources || tooManyTableSources) {
            issueType = issueType == null ? "OVER_CONNECTED" : issueType;
            severity = "HIGH";
            ruleHits.add("TOO_MANY_SOURCES");
            reason = columnName == null
                    ? "表级目标关联来源表和字段均过多，可能存在过连或别名解析异常"
                    : "单个目标字段关联来源过多，可能存在过连或别名解析异常";
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
        evidence.put("relationTypeDescriptions", relationTypeDescriptions());
        evidence.put("labels", object.get("labels"));
        evidence.put("metadataReviewHint", "confidence=LOW 或 ambiguityCode 非空表示物理模型驱动解析需要人工确认");
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

    private void applyAutomaticReviewStatus(LineageReviewIssue issue) {
        if ("REJECTED".equalsIgnoreCase(issue.getVerdict())) {
            issue.setReviewStatus("FALSE_POSITIVE");
            if (!StringUtils.hasText(issue.getReviewerNote())) {
                issue.setReviewerNote("AI 判定无问题，自动排除人工待处理");
            }
        }
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
        return hashOf(AI_REVIEW_PROMPT_VERSION, issue.getIssueType(), issue.getTableName(),
                issue.getColumnName(), issue.getFingerprint());
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

    private String normalizeSqlForAudit(String sql) {
        if (!StringUtils.hasText(sql)) {
            return "";
        }
        String normalized = sql.replaceAll("(?s)/\\*.*?\\*/", " ")
                .replaceAll("(?m)--.*?$", " ")
                .replaceAll("\\s+", " ")
                .trim();
        if (normalized.endsWith(";")) {
            normalized = normalized.substring(0, normalized.length() - 1).trim();
        }
        return normalized.toUpperCase(Locale.ROOT);
    }

    private Map<String, List<Map<String, Object>>> groupRelationsByType(Object relationsValue) {
        Map<String, List<Map<String, Object>>> grouped = new LinkedHashMap<>();
        if (!(relationsValue instanceof List<?> relations)) {
            return grouped;
        }
        for (Object value : relations) {
            if (!(value instanceof Map<?, ?> rawRelation)) {
                continue;
            }
            Map<String, Object> relation = new LinkedHashMap<>();
            rawRelation.forEach((key, relValue) -> {
                if (key != null) {
                    relation.put(String.valueOf(key), relValue);
                }
            });
            String relationType = toText(relation.get("relationType"));
            if (!StringUtils.hasText(relationType)) {
                relationType = "UNKNOWN";
            }
            grouped.computeIfAbsent(relationType, ignored -> new ArrayList<>()).add(relation);
        }
        return grouped;
    }

    private Map<String, String> relationTypeDescriptions() {
        Map<String, String> descriptions = new LinkedHashMap<>();
        descriptions.put("DERIVES_TO", "直接数据派生：源字段值直接组成、转换、计算或复制到目标字段。");
        descriptions.put("CASE_WHEN", "条件分支依赖：源字段出现在 CASE/IF 的 WHEN 条件中，只决定目标字段取哪个分支。");
        descriptions.put("FILTERS", "过滤依赖：源字段出现在 WHERE/HAVING 条件中，只影响结果集是否保留。");
        descriptions.put("JOINS", "关联依赖：源字段出现在 JOIN/ON 条件中，只影响表之间匹配。");
        descriptions.put("GROUPS", "分组依赖：源字段出现在 GROUP BY 中，只影响聚合粒度。");
        descriptions.put("ORDERS", "排序依赖：源字段出现在 ORDER BY 中，只影响排序或窗口顺序。");
        descriptions.put("CALLS", "调用依赖：源对象通过函数、过程或动态调用参与计算。");
        descriptions.put("REFERENCES", "引用依赖：源对象被 SQL 引用但不一定形成字段值派生。");
        return descriptions;
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

    private List<String> normalizeStringList(Object value) {
        if (!(value instanceof List<?> list)) {
            return Collections.emptyList();
        }
        Set<String> normalized = new LinkedHashSet<>();
        for (Object item : list) {
            String text = toText(item);
            if (StringUtils.hasText(text)) {
                normalized.add(text.trim());
            }
        }
        return new ArrayList<>(normalized);
    }

    private void appendMarkdownList(StringBuilder sb, String title, List<String> values) {
        if (values == null || values.isEmpty()) {
            return;
        }
        sb.append("- ").append(title).append(":\n");
        for (String value : values) {
            if (StringUtils.hasText(value)) {
                sb.append("  - ").append(value).append("\n");
            }
        }
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
