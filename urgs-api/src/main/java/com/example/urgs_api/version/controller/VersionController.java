package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.AppSystem;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.AppSystemService;
import com.example.urgs_api.version.service.GitRepositoryService;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;

import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/version")
@RequiredArgsConstructor
public class VersionController {

    private final AppSystemService appSystemService;
    private final GitRepositoryService gitRepositoryService;
    private final GitPlatformService gitPlatformService;

    // ===== 应用系统 API =====

    @GetMapping("/apps")
    public List<AppSystem> listApps(
            @RequestParam(required = false) String keyword,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return appSystemService.search(userId != null ? userId : 1L, keyword);
    }

    @GetMapping("/apps/{id}")
    public ResponseEntity<AppSystem> getApp(@PathVariable Long id) {
        return appSystemService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/apps")
    public AppSystem createApp(@RequestBody AppSystem app) {
        return appSystemService.create(app);
    }

    @PutMapping("/apps/{id}")
    public ResponseEntity<AppSystem> updateApp(@PathVariable Long id, @RequestBody AppSystem app) {
        try {
            return ResponseEntity.ok(appSystemService.update(id, app));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/apps/{id}")
    public ResponseEntity<Void> deleteApp(@PathVariable Long id) {
        appSystemService.delete(id);
        return ResponseEntity.ok().build();
    }

    // ===== 扩展 API =====
    @GetMapping("/repos/pr-counts")
    public Map<Long, Integer> getRepoPrCounts(@RequestAttribute(value = "userId", required = false) Long userId) {
        if (userId == null)
            userId = 1L;
        List<GitRepository> repos = gitRepositoryService.findAll(userId);

        // Parallel stream for faster fetching
        return repos.parallelStream()
                .collect(java.util.stream.Collectors.toMap(
                        GitRepository::getId,
                        repo -> gitPlatformService.getOpenPrCount(repo.getId())));
    }

    // ===== Git 仓库 API =====

    @GetMapping("/repos")
    public List<GitRepository> listRepos(
            @RequestParam(required = false) Long ssoId,
            @RequestParam(required = false) String platform,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        if (userId == null) {
            userId = 1L; // Fallback for dev environment or default user
        }

        // 1. Fetch filtered list from DB
        List<GitRepository> dbRepos;
        if (ssoId != null) {
            dbRepos = gitRepositoryService.findBySsoId(userId, ssoId);
        } else if (platform != null) {
            dbRepos = gitRepositoryService.findByPlatform(userId, platform);
        } else {
            dbRepos = gitRepositoryService.findAll(userId);
        }

        return dbRepos;
    }

    @GetMapping("/repos/{id}")
    public ResponseEntity<GitRepository> getRepo(@PathVariable Long id) {
        return gitRepositoryService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/repos")
    public GitRepository createRepo(@RequestBody GitRepository repo,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        return gitRepositoryService.create(repo, userId != null ? userId : 1L);
    }

    @PutMapping("/repos/{id}")
    public ResponseEntity<GitRepository> updateRepo(@PathVariable Long id, @RequestBody GitRepository repo) {
        try {
            return ResponseEntity.ok(gitRepositoryService.update(id, repo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/repos/{id}")
    public ResponseEntity<Void> deleteRepo(@PathVariable Long id) {
        gitRepositoryService.delete(id);
        return ResponseEntity.ok().build();
    }

    // ===== 概览统计 API =====

    @GetMapping("/overview")
    public Map<String, Object> getOverview() {
        List<AppSystem> apps = appSystemService.findAll();
        List<GitRepository> repos = gitRepositoryService.findAll();

        return Map.of(
                "totalApps", apps.size(),
                "totalRepos", repos.size(),
                "platforms", repos.stream()
                        .map(GitRepository::getPlatform)
                        .distinct()
                        .toList());
    }
}
