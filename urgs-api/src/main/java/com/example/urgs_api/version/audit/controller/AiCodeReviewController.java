package com.example.urgs_api.version.audit.controller;

import com.example.urgs_api.version.audit.entity.AiCodeReview;
import com.example.urgs_api.version.audit.service.AiCodeReviewService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/audit")
public class AiCodeReviewController {

    private final AiCodeReviewService aiCodeReviewService;

    public AiCodeReviewController(AiCodeReviewService aiCodeReviewService) {
        this.aiCodeReviewService = aiCodeReviewService;
    }

    /**
     * Trigger AI Code Review
     */
    @PostMapping("/trigger")
    public ResponseEntity<Void> triggerReview(
            @RequestParam Long repoId,
            @RequestParam String commitSha,
            @RequestParam(required = false) String branch,
            @RequestParam(required = false) String email) {
        aiCodeReviewService.triggerReview(repoId, commitSha, branch, email);
        return ResponseEntity.ok().build();
    }

    /**
     * List Reviews
     */
    @GetMapping("/list")
    public List<AiCodeReview> listReviews(
            @RequestParam(required = false) Long repoId,
            @RequestParam(required = false) Long developerId) {
        // Simple list all or filter logic. For now returning all.
        // If filters needed, use lambda query in service.
        return aiCodeReviewService.list();
    }

    /**
     * Get Review Detail
     */
    @GetMapping("/{id}")
    public ResponseEntity<AiCodeReview> getReview(@PathVariable Long id) {
        AiCodeReview review = aiCodeReviewService.getById(id);
        if (review == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(review);
    }

    /**
     * Get Review by Commit
     */
    @GetMapping("/commit/{sha}")
    public ResponseEntity<AiCodeReview> getReviewByCommit(@PathVariable String sha) {
        AiCodeReview review = aiCodeReviewService.getByCommit(sha);
        if (review == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(review);
    }
}
