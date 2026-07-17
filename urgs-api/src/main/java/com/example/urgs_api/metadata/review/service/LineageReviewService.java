package com.example.urgs_api.metadata.review.service;

import com.example.urgs_api.metadata.model.LineageAnalysisRecord;
import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;

import java.util.List;
import java.util.Map;

public interface LineageReviewService {

    List<LineageReviewTask> listTasks(String analysisRecordId, String status);

    List<LineageAnalysisRecord> listAnalysisRecords();

    Map<String, Object> triggerByAnalysisRecord(String analysisRecordId, boolean forceRerun);

    Map<String, Object> retryTask(Long taskId);

    void scheduleTasksForAnalysis(LineageAnalysisRecord record, boolean forceRerun);

    LineageReviewTask getTask(Long taskId);

    List<LineageReviewIssue> listIssues(Long taskId, String severity, String issueType, String reviewStatus);

    LineageReviewIssue getIssue(Long issueId);

    LineageReviewIssue decideIssue(Long issueId, Long reviewerId, LineageReviewDecisionRequest request);

    List<Map<String, Object>> getTaskSqlPreviews(Long taskId);

    byte[] exportTaskReport(Long taskId);
}
