package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.dto.GitPullRequest;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/repos")
@RequiredArgsConstructor
public class GitPullRequestController {

    private final GitPlatformService gitPlatformService;

    /**
     * 获取 Pull Request 列表
     */
    @GetMapping("/{repoId}/pulls")
    public ResponseEntity<List<GitPullRequest>> getPullRequests(
            @PathVariable Long repoId,
            @RequestParam(required = false, defaultValue = "all") String state,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer perPage) {
        List<GitPullRequest> prs = gitPlatformService.getPullRequests(repoId, state, page, perPage);
        return ResponseEntity.ok(prs);
    }

    /**
     * 获取 Pull Request 详情
     */
    @GetMapping("/{repoId}/pulls/{number}")
    public ResponseEntity<GitPullRequest> getPullRequest(
            @PathVariable Long repoId,
            @PathVariable Long number) {
        GitPullRequest pr = gitPlatformService.getPullRequest(repoId, number);
        return ResponseEntity.ok(pr);
    }

    /**
     * 创建 Pull Request
     */
    @PostMapping("/{repoId}/pulls")
    public ResponseEntity<Void> createPullRequest(
            @PathVariable Long repoId,
            @RequestBody CreatePullRequestRequest request,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        // Token logic: In production this should come from user's linked account
        // For now relying on repository token or user token passed in header if
        // adjusted
        // But service signature accepts token. GitBrowserController passed userToken as
        // null.
        // We will do the same here unless we have a token management system ready.
        // Assuming the repository has an access token configured.

        String userToken = null; // Placeholder

        gitPlatformService.createPullRequest(repoId, request.getTitle(), request.getBody(), request.getHead(),
                request.getBase(), userToken);
        return ResponseEntity.ok().build();
    }

    @Data
    public static class CreatePullRequestRequest {
        private String title;
        private String body;
        private String head; // source branch
        private String base; // target branch
    }
}
