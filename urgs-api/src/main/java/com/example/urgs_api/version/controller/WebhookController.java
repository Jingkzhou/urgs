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
    private void handlePushEvent(Long repoId, String platform, JsonNode payload) {
        String ref = payload.has("ref") ? payload.get("ref").asText() : "";
        String branch = ref.replace("refs/heads/", "");

        log.info("Push to repo {} ({}) on branch: {}", repoId, platform, branch);

        // TODO: 触发流水线执行
        // pipelineService.triggerByWebhook(repoId, branch, payload);
    }
}
