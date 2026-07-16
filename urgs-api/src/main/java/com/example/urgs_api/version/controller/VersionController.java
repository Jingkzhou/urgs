package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.AppSystem;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.AppSystemService;
import com.example.urgs_api.version.service.GitRepositoryService;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.auth.annotation.RequirePermission;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.http.HttpStatus;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;
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
        List<GitRepository> repos = findReposForUserSystems(userId);

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

        return findReposForUserSystems(userId).stream()
                .filter(repo -> ssoId == null || ssoId.equals(repo.getSsoId()))
                .filter(repo -> platform == null || platform.equalsIgnoreCase(repo.getPlatform()))
                .toList();
    }

    /** 系统管理使用的全量仓库维护列表。 */
    @GetMapping("/repos/management")
    @RequirePermission("sys:repo:query")
    public List<GitRepository> listManagedRepos() {
        return gitRepositoryService.findAll();
    }

    @GetMapping("/repos/management/pr-counts")
    @RequirePermission("sys:repo:query")
    public Map<Long, Integer> getManagedRepoPrCounts() {
        return gitRepositoryService.findAll().parallelStream()
                .collect(java.util.stream.Collectors.toMap(
                        GitRepository::getId,
                        repo -> gitPlatformService.getOpenPrCount(repo.getId())));
    }

    @GetMapping("/repos/{id}")
    public ResponseEntity<GitRepository> getRepo(@PathVariable Long id) {
        return gitRepositoryService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/repos")
    @RequirePermission("sys:repo:add")
    public GitRepository createRepo(@RequestBody GitRepository repo,
            @RequestAttribute(value = "userId", required = false) Long userId) {
        Long currentUserId = userId != null ? userId : 1L;
        try {
            String accessToken = gitRepositoryService.getPersonalAccessToken(currentUserId, repo.getPlatform());
            gitPlatformService.verifyRepositoryAccess(repo, accessToken);
            return gitRepositoryService.create(repo, currentUserId);
        } catch (IllegalArgumentException e) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, e.getMessage());
        }
    }

    @PutMapping("/repos/{id}")
    @RequirePermission("sys:repo:edit")
    public ResponseEntity<GitRepository> updateRepo(@PathVariable Long id, @RequestBody GitRepository repo) {
        try {
            return ResponseEntity.ok(gitRepositoryService.update(id, repo));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.notFound().build();
        }
    }

    @DeleteMapping("/repos/{id}")
    @RequirePermission("sys:repo:del")
    public ResponseEntity<Void> deleteRepo(@PathVariable Long id) {
        gitRepositoryService.delete(id);
        return ResponseEntity.ok().build();
    }

    private List<GitRepository> findReposForUserSystems(Long userId) {
        return gitRepositoryService.findAccessibleByUser(userId);
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
