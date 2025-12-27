package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.AICodeReview;
import com.example.urgs_api.version.service.CodeReviewService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/version/audit")
@RequiredArgsConstructor
public class AICodeAuditController {

    private final CodeReviewService codeReviewService;

    /**
     * Manually trigger an AI Code Review for a specific commit
     */
    @PostMapping("/trigger")
    public ResponseEntity<AICodeReview> triggerReview(
            @RequestParam Long repoId,
            @RequestParam String commitSha,
            @RequestParam(required = false) String branch,
            @RequestParam(required = false) String email) {
        log.info("Manually triggering AI Code Review for repo: {}, commit: {}", repoId, commitSha);
        AICodeReview review = codeReviewService.triggerReview(repoId, commitSha, branch, email);
        return ResponseEntity.ok(review);
    }

    /**
     * Get review details by ID
     */
    @GetMapping("/{id}")
    public ResponseEntity<AICodeReview> getReviewDetail(@PathVariable Long id) {
        return ResponseEntity.ok(codeReviewService.getReviewById(id));
    }

    /**
     * List reviews, optionally filtered by repo or developer
     */
    @GetMapping("/list")
    public ResponseEntity<List<AICodeReview>> listReviews(
            @RequestParam(required = false) Long repoId,
            @RequestParam(required = false) Long developerId) {
        return ResponseEntity.ok(codeReviewService.listReviews(repoId, developerId));
    }

    /**
     * Get latest review for a specific commit
     */
    @GetMapping("/commit/{commitSha}")
    public ResponseEntity<AICodeReview> getReviewByCommit(@PathVariable String commitSha) {
        return ResponseEntity.of(codeReviewService.getReviewByCommit(commitSha));
    }
}
