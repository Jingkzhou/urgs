package com.example.urgs_api.metadata.review.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewStatementAudit;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;
import com.example.urgs_api.metadata.review.mapper.LineageReviewIssueMapper;
import com.example.urgs_api.metadata.review.mapper.LineageReviewStatementAuditMapper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.Collections;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Collectors;

@Service
public class LineageReviewTaskSummaryService {

    private final LineageReviewIssueMapper issueMapper;
    private final LineageReviewStatementAuditMapper statementAuditMapper;

    public LineageReviewTaskSummaryService(
            LineageReviewIssueMapper issueMapper,
            LineageReviewStatementAuditMapper statementAuditMapper) {
        this.issueMapper = issueMapper;
        this.statementAuditMapper = statementAuditMapper;
    }

    public void attachSummaries(List<LineageReviewTask> tasks) {
        if (tasks == null || tasks.isEmpty()) {
            return;
        }
        List<Long> taskIds = tasks.stream()
                .map(LineageReviewTask::getId)
                .filter(Objects::nonNull)
                .toList();
        if (taskIds.isEmpty()) {
            tasks.forEach(task -> attachSummaryFields(task, Collections.emptyList(), Collections.emptyList()));
            return;
        }

        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.select(
                LineageReviewIssue::getTaskId,
                LineageReviewIssue::getVerdict,
                LineageReviewIssue::getReviewStatus);
        query.in(LineageReviewIssue::getTaskId, taskIds);
        List<LineageReviewIssue> issues = issueMapper.selectList(query);
        Map<Long, List<LineageReviewIssue>> issueMap = issues.stream()
                .filter(issue -> issue.getTaskId() != null)
                .collect(Collectors.groupingBy(LineageReviewIssue::getTaskId));
        LambdaQueryWrapper<LineageReviewStatementAudit> statementQuery = new LambdaQueryWrapper<>();
        statementQuery.select(
                LineageReviewStatementAudit::getTaskId,
                LineageReviewStatementAudit::getAuditStatus,
                LineageReviewStatementAudit::getIsHighRisk,
                LineageReviewStatementAudit::getIssueCount);
        statementQuery.in(LineageReviewStatementAudit::getTaskId, taskIds);
        Map<Long, List<LineageReviewStatementAudit>> statementMap = statementAuditMapper.selectList(statementQuery).stream()
                .filter(audit -> audit.getTaskId() != null)
                .collect(Collectors.groupingBy(LineageReviewStatementAudit::getTaskId));

        tasks.forEach(task -> attachSummaryFields(
                task,
                issueMap.getOrDefault(task.getId(), Collections.emptyList()),
                statementMap.getOrDefault(task.getId(), Collections.emptyList())));
    }

    public void attachSummary(LineageReviewTask task) {
        if (task == null) {
            return;
        }
        if (task.getId() == null) {
            attachSummaryFields(task, Collections.emptyList(), Collections.emptyList());
            return;
        }
        LambdaQueryWrapper<LineageReviewIssue> issueQuery = new LambdaQueryWrapper<>();
        issueQuery.select(
                LineageReviewIssue::getTaskId,
                LineageReviewIssue::getVerdict,
                LineageReviewIssue::getReviewStatus);
        issueQuery.eq(LineageReviewIssue::getTaskId, task.getId());
        LambdaQueryWrapper<LineageReviewStatementAudit> statementQuery = new LambdaQueryWrapper<>();
        statementQuery.select(
                LineageReviewStatementAudit::getTaskId,
                LineageReviewStatementAudit::getAuditStatus,
                LineageReviewStatementAudit::getIsHighRisk,
                LineageReviewStatementAudit::getIssueCount);
        statementQuery.eq(LineageReviewStatementAudit::getTaskId, task.getId());
        attachSummaryFields(task, issueMapper.selectList(issueQuery), statementAuditMapper.selectList(statementQuery));
    }

    private void attachSummaryFields(
            LineageReviewTask task,
            List<LineageReviewIssue> issues,
            List<LineageReviewStatementAudit> statementAudits) {
        int pending = 0;
        int confirmed = 0;
        int falsePositive = 0;
        int resolved = 0;
        int ignored = 0;

        for (LineageReviewIssue issue : issues) {
            String status = normalizeEffectiveReviewStatus(issue);
            switch (status) {
                case "CONFIRMED" -> confirmed++;
                case "FALSE_POSITIVE" -> falsePositive++;
                case "RESOLVED" -> resolved++;
                case "IGNORED" -> ignored++;
                default -> pending++;
            }
        }

        int total = issues.size();
        int reviewed = confirmed + falsePositive + resolved + ignored;
        task.setPendingIssueCount(pending);
        task.setConfirmedIssueCount(confirmed);
        task.setFalsePositiveIssueCount(falsePositive);
        task.setResolvedIssueCount(resolved);
        task.setIgnoredIssueCount(ignored);
        task.setReviewedIssueCount(reviewed);
        task.setTotalReviewIssueCount(total);
        task.setReviewCompletionRate(total == 0 ? terminalProgress(task) : percent(reviewed, total));
        task.setExecutionProgressRate(resolveExecutionProgress(task));
        attachStatementAuditSummary(task, statementAudits);
    }

    private void attachStatementAuditSummary(
            LineageReviewTask task,
            List<LineageReviewStatementAudit> statementAudits) {
        int covered = 0;
        int verified = 0;
        int noIssue = 0;
        int skipped = 0;
        int failed = 0;
        int highRisk = 0;
        for (LineageReviewStatementAudit audit : statementAudits) {
            String status = normalizeReviewStatus(audit.getAuditStatus());
            if (Boolean.TRUE.equals(audit.getIsHighRisk())) {
                highRisk++;
            }
            switch (status) {
                case "SCREENED_NO_ISSUE" -> {
                    covered++;
                    noIssue++;
                }
                case "WAITING_VERIFICATION" -> covered++;
                case "VERIFIED_ISSUE" -> {
                    covered++;
                    verified++;
                }
                case "VERIFIED_NO_ISSUE" -> {
                    covered++;
                    verified++;
                    noIssue++;
                }
                case "CACHED" -> {
                    covered++;
                    verified++;
                    if (audit.getIssueCount() == null || audit.getIssueCount() == 0) {
                        noIssue++;
                    }
                }
                case "SKIPPED_BUDGET" -> skipped++;
                case "FAILED" -> failed++;
                default -> {
                }
            }
        }
        task.setScreenedStatementCount(covered);
        task.setVerifiedStatementCount(verified);
        task.setNoIssueStatementCount(noIssue);
        task.setSkippedStatementCount(skipped);
        task.setFailedStatementAuditCount(failed);
        task.setHighRiskStatementCount(highRisk);
        int totalStatements = task.getObjectCount() == null ? 0 : task.getObjectCount();
        task.setStatementCoverageRate((task.getTokenBudget() == null || task.getTokenBudget() > 0)
                ? percent(covered, totalStatements)
                : 0);
    }

    private String normalizeEffectiveReviewStatus(LineageReviewIssue issue) {
        if (issue != null && "REJECTED".equalsIgnoreCase(issue.getVerdict())) {
            return "FALSE_POSITIVE";
        }
        return normalizeReviewStatus(issue == null ? null : issue.getReviewStatus());
    }

    private String normalizeReviewStatus(String value) {
        if (!StringUtils.hasText(value)) {
            return "PENDING";
        }
        return value.trim().toUpperCase(Locale.ROOT);
    }

    private int resolveExecutionProgress(LineageReviewTask task) {
        int total = task.getObjectCount() == null ? 0 : task.getObjectCount();
        int processed = task.getProcessedCount() == null ? 0 : task.getProcessedCount();
        if (total <= 0) {
            return terminalProgress(task);
        }
        return percent(Math.min(processed, total), total);
    }

    private int terminalProgress(LineageReviewTask task) {
        String status = task.getStatus() == null ? "" : task.getStatus().toUpperCase(Locale.ROOT);
        return ("COMPLETED".equals(status) || "DEGRADED".equals(status) || "FAILED".equals(status)) ? 100 : 0;
    }

    private int percent(int value, int total) {
        if (total <= 0) {
            return 0;
        }
        return Math.min(100, Math.max(0, Math.round(value * 100f / total)));
    }
}
