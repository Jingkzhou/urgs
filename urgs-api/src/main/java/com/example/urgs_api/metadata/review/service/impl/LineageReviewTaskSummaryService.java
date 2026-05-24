package com.example.urgs_api.metadata.review.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;
import com.example.urgs_api.metadata.review.mapper.LineageReviewIssueMapper;
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

    public LineageReviewTaskSummaryService(LineageReviewIssueMapper issueMapper) {
        this.issueMapper = issueMapper;
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
            tasks.forEach(task -> attachIssueSummary(task, Collections.emptyList()));
            return;
        }

        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.in(LineageReviewIssue::getTaskId, taskIds);
        List<LineageReviewIssue> issues = issueMapper.selectList(query);
        Map<Long, List<LineageReviewIssue>> issueMap = issues.stream()
                .filter(issue -> issue.getTaskId() != null)
                .collect(Collectors.groupingBy(LineageReviewIssue::getTaskId));

        tasks.forEach(task -> attachIssueSummary(task, issueMap.getOrDefault(task.getId(), Collections.emptyList())));
    }

    public void attachSummary(LineageReviewTask task) {
        if (task == null) {
            return;
        }
        if (task.getId() == null) {
            attachIssueSummary(task, Collections.emptyList());
            return;
        }
        LambdaQueryWrapper<LineageReviewIssue> query = new LambdaQueryWrapper<>();
        query.eq(LineageReviewIssue::getTaskId, task.getId());
        attachIssueSummary(task, issueMapper.selectList(query));
    }

    private void attachIssueSummary(LineageReviewTask task, List<LineageReviewIssue> issues) {
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
