package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.AppSystem;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.AppSystemService;
import com.example.urgs_api.version.service.GitRepositoryService;
import com.example.urgs_api.user.service.UserService;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.dto.GitProjectVO;
import com.example.urgs_api.user.model.User;
import lombok.RequiredArgsConstructor;
import java.util.Set;
import java.util.Collections;
import java.util.stream.Collectors;

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
    private final UserService userService;
    private final GitPlatformService gitPlatformService;

    // ===== 应用系统 API =====

    @GetMapping("/apps")
    public List<AppSystem> listApps(@RequestParam(required = false) String keyword) {
        return appSystemService.search(keyword);
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

    // ===== Git 仓库 API =====

    @GetMapping("/repos")
    public List<GitRepository> listRepos(
            @RequestParam(required = false) Long ssoId,
            @RequestParam(required = false) String platform,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        // 1. Fetch raw list from DB
        List<GitRepository> dbRepos;
        if (ssoId != null) {
            dbRepos = gitRepositoryService.findBySsoId(ssoId);
        } else if (platform != null) {
            dbRepos = gitRepositoryService.findByPlatform(platform);
        } else {
            dbRepos = gitRepositoryService.findAll();
        }

        // 2. Filter by User Permissions (Strict Visibility)
        // Only show repositories that execute "Sync" logic would see.
        if (userId == null) {
            userId = 1L; // Fallback for dev environment or default user
        }

        User user = userService.getById(userId);
        if (user == null) {
            return Collections.emptyList();
        }

        // GitLab permission check
        // We only filter 'gitlab' repos strictly. Others passed by default or need
        // similar logic.
        try {
            String token = user.getGitAccessToken();
            Set<String> allowedPaths = Collections.emptySet();

            if (token != null && !token.isEmpty()) {
                List<GitProjectVO> allowedProjects = gitPlatformService.getGitLabProjects(token);
                allowedPaths = allowedProjects.stream()
                        .map(GitProjectVO::getPathWithNamespace)
                        .collect(Collectors.toSet());
            }

            // Effectively final for lambda
            Set<String> finalAllowedPaths = allowedPaths;

            return dbRepos.stream()
                    .filter(repo -> {
                        if ("gitlab".equalsIgnoreCase(repo.getPlatform())) {
                            // Strict check: Must match a project in the user's allowed list
                            return finalAllowedPaths.contains(repo.getFullName());
                        }
                        // For other platforms (gitee/github), pass through for now
                        return true;
                    })
                    .collect(Collectors.toList());

        } catch (Exception e) {
            // Log error and return empty list or fail safe?
            // If checking permissions fails, fail safe -> show nothing or show all?
            // Security first: show nothing (or just the ones not requiring check?)
            // Returning empty list for safety.
            System.err.println("Failed to filter repositories: " + e.getMessage());
            return Collections.emptyList();
        }
    }

    @GetMapping("/repos/{id}")
    public ResponseEntity<GitRepository> getRepo(@PathVariable Long id) {
        return gitRepositoryService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/repos")
    public GitRepository createRepo(@RequestBody GitRepository repo) {
        return gitRepositoryService.create(repo);
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
