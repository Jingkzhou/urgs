package com.example.urgs_api.version.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

/**
 * Webhook 接收控制器
 * 接收来自 GitLab/Gitee/GitHub 的 webhook 事件
 */
@Slf4j
@RestController
@RequestMapping("/api/webhook")
@RequiredArgsConstructor
public class WebhookController {

    private final ObjectMapper objectMapper;

    /**
     * 接收 Gitee Webhook
     */
    @PostMapping("/gitee/{repoId}")
    public ResponseEntity<Map<String, String>> handleGiteeWebhook(
            @PathVariable Long repoId,
            @RequestHeader(value = "X-Gitee-Token", required = false) String token,
            @RequestHeader(value = "X-Gitee-Event", required = false) String event,
            @RequestBody JsonNode payload) {

        log.info("Received Gitee webhook for repo {}: event={}", repoId, event);

        // TODO: 验证 token
        // TODO: 根据 event 类型处理（push, merge_request, tag_push 等）

        if ("Push Hook".equals(event) || "push".equals(event)) {
            handlePushEvent(repoId, "gitee", payload);
        }

        return ResponseEntity.ok(Map.of("status", "received", "event", String.valueOf(event)));
    }

    /**
     * 接收 GitLab Webhook
     */
    @PostMapping("/gitlab/{repoId}")
    public ResponseEntity<Map<String, String>> handleGitLabWebhook(
            @PathVariable Long repoId,
            @RequestHeader(value = "X-Gitlab-Token", required = false) String token,
            @RequestHeader(value = "X-Gitlab-Event", required = false) String event,
            @RequestBody JsonNode payload) {

        log.info("Received GitLab webhook for repo {}: event={}", repoId, event);

        if ("Push Hook".equals(event)) {
            handlePushEvent(repoId, "gitlab", payload);
        }

        return ResponseEntity.ok(Map.of("status", "received", "event", String.valueOf(event)));
    }

    /**
     * 接收 GitHub Webhook
     */
    @PostMapping("/github/{repoId}")
    public ResponseEntity<Map<String, String>> handleGitHubWebhook(
            @PathVariable Long repoId,
            @RequestHeader(value = "X-Hub-Signature-256", required = false) String signature,
            @RequestHeader(value = "X-GitHub-Event", required = false) String event,
            @RequestBody JsonNode payload) {

        log.info("Received GitHub webhook for repo {}: event={}", repoId, event);

        if ("push".equals(event)) {
            handlePushEvent(repoId, "github", payload);
        }

        return ResponseEntity.ok(Map.of("status", "received", "event", String.valueOf(event)));
    }

    /**
     * 处理 Push 事件
     */
    private final com.example.urgs_api.version.service.CodeReviewService codeReviewService;

    /**
     * 处理 Push 事件
     */
    private void handlePushEvent(Long repoId, String platform, JsonNode payload) {
        String ref = payload.has("ref") ? payload.get("ref").asText() : "";
        String branch = ref.replace("refs/heads/", "");

        String commitSha = null;
        String authorEmail = null;

        // Try to identify commit info based on platform/payload structure
        if (payload.has("head_commit") && !payload.get("head_commit").isNull()) {
            JsonNode headCommit = payload.get("head_commit");
            commitSha = headCommit.get("id").asText();
            if (headCommit.has("author")) {
                authorEmail = headCommit.get("author").get("email").asText();
            }
        } else if (payload.has("commits") && payload.get("commits").isArray() && payload.get("commits").size() > 0) {
            JsonNode latest = payload.get("commits").get(0); // Simplistic fallback
            commitSha = latest.get("id").asText();
            if (latest.has("author")) {
                authorEmail = latest.get("author").get("email").asText();
            }
        } else if (payload.has("after")) {
            commitSha = payload.get("after").asText();
            if (payload.has("user_email")) {
                authorEmail = payload.get("user_email").asText();
            }
        }

        log.info("Push to repo {} ({}) on branch: {}, sha: {}, email: {}", repoId, platform, branch, commitSha,
                authorEmail);

        if (commitSha != null && !commitSha.equals("0000000000000000000000000000000000000000")) {
            // Trigger AI Code Review
            try {
                codeReviewService.triggerReview(repoId, commitSha, branch, authorEmail);
            } catch (Exception e) {
                log.error("Failed to trigger AI review", e);
            }
        }

        // TODO: 触发流水线执行
        // pipelineService.triggerByWebhook(repoId, branch, payload);
    }
}
