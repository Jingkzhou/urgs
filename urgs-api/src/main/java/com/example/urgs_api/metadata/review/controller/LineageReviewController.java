package com.example.urgs_api.metadata.review.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.review.dto.LineageReviewDecisionRequest;
import com.example.urgs_api.metadata.review.dto.LineageReviewMemoryRequest;
import com.example.urgs_api.metadata.review.dto.LineageReviewTriggerRequest;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewMemory;
import com.example.urgs_api.metadata.review.entity.LineageReviewTask;
import com.example.urgs_api.metadata.review.service.LineageReviewMaintenanceService;
import com.example.urgs_api.metadata.review.service.LineageReviewMemoryService;
import com.example.urgs_api.metadata.review.service.LineageReviewService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/metadata/lineage/review")
public class LineageReviewController {

    private final LineageReviewService lineageReviewService;
    private final LineageReviewMaintenanceService maintenanceService;
    private final LineageReviewMemoryService memoryService;

    public LineageReviewController(
            LineageReviewService lineageReviewService,
            LineageReviewMaintenanceService maintenanceService,
            LineageReviewMemoryService memoryService) {
        this.lineageReviewService = lineageReviewService;
        this.maintenanceService = maintenanceService;
        this.memoryService = memoryService;
    }

    @GetMapping("/records")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<List<?>> listRecords() {
        return ResponseEntity.ok(lineageReviewService.listAnalysisRecords());
    }

    @GetMapping("/tasks")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<List<LineageReviewTask>> listTasks(
            @RequestParam(required = false) String analysisRecordId,
            @RequestParam(required = false) String status) {
        return ResponseEntity.ok(lineageReviewService.listTasks(analysisRecordId, status));
    }

    @PostMapping("/tasks/trigger")
    @RequirePermission("version:ai:trigger")
    public ResponseEntity<Map<String, Object>> trigger(@RequestBody LineageReviewTriggerRequest request) {
        return ResponseEntity.ok(lineageReviewService.triggerByAnalysisRecord(
                request.getAnalysisRecordId(),
                Boolean.TRUE.equals(request.getForceRerun())));
    }

    @PostMapping("/tasks/{taskId}/retry")
    @RequirePermission("version:ai:trigger")
    public ResponseEntity<Map<String, Object>> retryTask(@PathVariable Long taskId) {
        return ResponseEntity.ok(lineageReviewService.retryTask(taskId));
    }

    @DeleteMapping("/history")
    @RequirePermission("version:ai:trigger")
    public ResponseEntity<Map<String, Object>> clearHistory() {
        return ResponseEntity.ok(maintenanceService.clearHistory());
    }

    @GetMapping("/tasks/{taskId}")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<LineageReviewTask> getTask(@PathVariable Long taskId) {
        LineageReviewTask task = lineageReviewService.getTask(taskId);
        return task == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(task);
    }

    @GetMapping("/tasks/{taskId}/sql-preview")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<List<Map<String, Object>>> getTaskSqlPreview(@PathVariable Long taskId) {
        return ResponseEntity.ok(lineageReviewService.getTaskSqlPreviews(taskId));
    }

    @GetMapping("/issues")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<List<LineageReviewIssue>> listIssues(
            @RequestParam(required = false) Long taskId,
            @RequestParam(required = false) String severity,
            @RequestParam(required = false) String issueType,
            @RequestParam(required = false) String reviewStatus) {
        return ResponseEntity.ok(lineageReviewService.listIssues(taskId, severity, issueType, reviewStatus));
    }

    @GetMapping("/issues/{issueId}")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<LineageReviewIssue> getIssue(@PathVariable Long issueId) {
        LineageReviewIssue issue = lineageReviewService.getIssue(issueId);
        return issue == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(issue);
    }

    @PutMapping("/issues/{issueId}/decision")
    @RequirePermission("version:ai:trigger")
    public ResponseEntity<LineageReviewIssue> decideIssue(
            @PathVariable Long issueId,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestBody LineageReviewDecisionRequest request) {
        if (isFalsePositiveWithoutReason(request)) {
            return ResponseEntity.badRequest().build();
        }
        if (isConfirmedWithoutProblemType(request)) {
            return ResponseEntity.badRequest().build();
        }
        normalizeFalsePositiveNote(request);
        LineageReviewIssue issue = lineageReviewService.decideIssue(issueId, userId, request);
        memoryService.captureFalsePositive(issue, userId, request);
        return ResponseEntity.ok(issue);
    }

    @GetMapping("/memories")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<List<LineageReviewMemory>> listMemories(
            @RequestParam(required = false) String status) {
        return ResponseEntity.ok(memoryService.listMemories(status));
    }

    @GetMapping("/memories/{memoryId}")
    @RequirePermission("version:ai:audit")
    public ResponseEntity<LineageReviewMemory> getMemory(@PathVariable Long memoryId) {
        LineageReviewMemory memory = memoryService.getMemory(memoryId);
        return memory == null ? ResponseEntity.notFound().build() : ResponseEntity.ok(memory);
    }

    @PutMapping("/memories/{memoryId}")
    @RequirePermission("version:ai:trigger")
    public ResponseEntity<LineageReviewMemory> updateMemory(
            @PathVariable Long memoryId,
            @RequestHeader(value = "X-User-Id", required = false) Long userId,
            @RequestBody LineageReviewMemoryRequest request) {
        return ResponseEntity.ok(memoryService.updateMemory(memoryId, userId, request));
    }

    @GetMapping("/export")
    @RequirePermission("version:ai:export")
    public void export(@RequestParam Long taskId, HttpServletResponse response) throws Exception {
        byte[] body = lineageReviewService.exportTaskReport(taskId);
        String fileName = URLEncoder.encode("lineage-review-" + taskId + ".md", StandardCharsets.UTF_8);
        response.setContentType(MediaType.TEXT_MARKDOWN_VALUE);
        response.setHeader(HttpHeaders.CONTENT_DISPOSITION, "attachment;filename*=utf-8''" + fileName);
        response.getOutputStream().write(body);
    }

    private boolean isFalsePositiveWithoutReason(LineageReviewDecisionRequest request) {
        if (request == null || !"FALSE_POSITIVE".equalsIgnoreCase(request.getReviewStatus())) {
            return false;
        }
        return !hasText(request.getFalsePositiveReason()) && !hasText(request.getReviewerNote());
    }

    private boolean isConfirmedWithoutProblemType(LineageReviewDecisionRequest request) {
        if (request == null || !"CONFIRMED".equalsIgnoreCase(request.getReviewStatus())) {
            return false;
        }
        return !hasText(request.getConfirmedProblemType());
    }

    private void normalizeFalsePositiveNote(LineageReviewDecisionRequest request) {
        if (request == null || !"FALSE_POSITIVE".equalsIgnoreCase(request.getReviewStatus())) {
            return;
        }
        if (!hasText(request.getReviewerNote()) && hasText(request.getFalsePositiveReason())) {
            request.setReviewerNote(request.getFalsePositiveReason().trim());
        }
    }

    private boolean hasText(String value) {
        return value != null && !value.trim().isEmpty();
    }
}
