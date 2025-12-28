package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.dto.GitBranch;
import com.example.urgs_api.version.dto.GitTag;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitFileContent;
import com.example.urgs_api.version.dto.GitFileEntry;
import com.example.urgs_api.version.service.GitPlatformService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * Git 仓库浏览 API
 */
@RestController
@RequestMapping("/api/version/repos")
@RequiredArgsConstructor
public class GitBrowserController {

    private final GitPlatformService gitPlatformService;

    /**
     * 获取文件树
     */
    @GetMapping("/{repoId}/tree")
    public ResponseEntity<List<GitFileEntry>> getFileTree(
            @PathVariable Long repoId,
            @RequestParam(required = false, defaultValue = "") String ref,
            @RequestParam(required = false, defaultValue = "") String path) {
        List<GitFileEntry> entries = gitPlatformService.getFileTree(repoId, ref, path);
        return ResponseEntity.ok(entries);
    }

    /**
     * 获取分支列表
     */
    @GetMapping("/{repoId}/branches")
    public ResponseEntity<List<GitBranch>> getBranches(@PathVariable Long repoId) {
        List<GitBranch> branches = gitPlatformService.getBranches(repoId);
        return ResponseEntity.ok(branches);
    }

    /**
     * 获取标签列表
     */
    @GetMapping("/{repoId}/tags")
    public ResponseEntity<List<GitTag>> getTags(@PathVariable Long repoId) {
        List<GitTag> tags = gitPlatformService.getTags(repoId);
        return ResponseEntity.ok(tags);
    }

    /**
     * 获取最新提交
     */
    @GetMapping("/{repoId}/commits/latest")
    public ResponseEntity<GitCommit> getLatestCommit(
            @PathVariable Long repoId,
            @RequestParam(required = false, defaultValue = "") String ref) {
        GitCommit commit = gitPlatformService.getLatestCommit(repoId, ref);
        return ResponseEntity.ok(commit);
    }

    /**
     * 获取提交列表
     */
    @GetMapping("/{repoId}/commits")
    public ResponseEntity<List<GitCommit>> getCommits(
            @PathVariable Long repoId,
            @RequestParam(required = false, defaultValue = "") String ref,
            @RequestParam(required = false, defaultValue = "1") Integer page,
            @RequestParam(required = false, defaultValue = "20") Integer perPage) {
        List<GitCommit> commits = gitPlatformService.getCommits(repoId, ref, page, perPage);
        return ResponseEntity.ok(commits);
    }

    /**
     * 获取提交详情
     */
    @GetMapping("/{repoId}/commits/{sha}")
    public ResponseEntity<GitCommit> getCommitDetail(
            @PathVariable Long repoId,
            @PathVariable String sha) {
        GitCommit commit = gitPlatformService.getCommitDetail(repoId, sha);
        return ResponseEntity.ok(commit);
    }

    /**
     * 获取文件内容
     */
    @GetMapping("/{repoId}/file")
    public ResponseEntity<GitFileContent> getFileContent(
            @PathVariable Long repoId,
            @RequestParam String path,
            @RequestParam(required = false, defaultValue = "") String ref) {
        GitFileContent content = gitPlatformService.getFileContent(repoId, ref, path);
        return ResponseEntity.ok(content);
    }

    /**
     * 创建分支
     */
    @PostMapping("/{repoId}/branches")
    public ResponseEntity<Void> createBranch(
            @PathVariable Long repoId,
            @RequestParam String name,
            @RequestParam String ref,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        String userToken = null;
        // User Git token integration removed

        gitPlatformService.createBranch(repoId, name, ref, userToken);
        return ResponseEntity.ok().build();
    }

    /**
     * 删除分支
     */
    @DeleteMapping("/{repoId}/branches/{name}")
    public ResponseEntity<Void> deleteBranch(
            @PathVariable Long repoId,
            @PathVariable String name,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        String userToken = null;
        // User Git token integration removed

        gitPlatformService.deleteBranch(repoId, name, userToken);
        return ResponseEntity.ok().build();
    }

    /**
     * 创建标签
     */
    @PostMapping("/{repoId}/tags")
    public ResponseEntity<Void> createTag(
            @PathVariable Long repoId,
            @RequestParam String name,
            @RequestParam String ref,
            @RequestParam(required = false) String message,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        String userToken = null;
        // User Git token integration removed

        gitPlatformService.createTag(repoId, name, ref, message, userToken);
        return ResponseEntity.ok().build();
    }

    /**
     * 删除标签
     */
    @DeleteMapping("/{repoId}/tags/{name}")
    public ResponseEntity<Void> deleteTag(
            @PathVariable Long repoId,
            @PathVariable String name,
            @RequestAttribute(value = "userId", required = false) Long userId) {

        String userToken = null;
        // User Git token integration removed

        gitPlatformService.deleteTag(repoId, name, userToken);
        return ResponseEntity.ok().build();
    }

    /**
     * 下载归档
     */
    @GetMapping("/{repoId}/archive")
    public ResponseEntity<org.springframework.core.io.InputStreamResource> downloadArchive(
            @PathVariable Long repoId,
            @RequestParam String ref) {

        java.io.InputStream inputStream = gitPlatformService.downloadArchive(repoId, ref);
        return ResponseEntity.ok()
                .header(org.springframework.http.HttpHeaders.CONTENT_DISPOSITION,
                        "attachment; filename=\"" + ref + ".zip\"")
                .contentType(org.springframework.http.MediaType.APPLICATION_OCTET_STREAM)
                .body(new org.springframework.core.io.InputStreamResource(inputStream));
    }

    private final com.example.urgs_api.user.service.UserService userService;
    private final com.example.urgs_api.version.service.GitRepositoryService gitRepositoryService;

    /**
     * 获取用户在 GitLab 上的项目列表
     */
    @GetMapping("/sync")
    public ResponseEntity<List<com.example.urgs_api.version.dto.GitProjectVO>> listGitLabProjects(
            @RequestAttribute(value = "userId", required = false) Long userId) {
        if (userId == null) {
            userId = 1L; // Fallback for dev
        }

        com.example.urgs_api.user.model.User user = userService.getById(userId);
        if (user == null) {
            throw new RuntimeException("User not found");
        }

        // User Git token integration removed
        return ResponseEntity.ok(java.util.Collections.emptyList());
    }

    /**
     * 导入选中的仓库
     */
    @PostMapping("/import")
    public ResponseEntity<Void> importRepositories(
            @RequestBody com.example.urgs_api.version.dto.GitImportRequest request) {
        if (request.getSystemId() == null) {
            throw new IllegalArgumentException("System ID is required");
        }
        if (request.getProjects() == null || request.getProjects().isEmpty()) {
            throw new IllegalArgumentException("No projects selected");
        }

        for (com.example.urgs_api.version.dto.GitProjectVO project : request.getProjects()) {
            com.example.urgs_api.version.entity.GitRepository repo = new com.example.urgs_api.version.entity.GitRepository();
            repo.setSsoId(request.getSystemId());
            repo.setName(project.getName());
            repo.setFullName(project.getPathWithNamespace());
            repo.setCloneUrl(project.getCloneUrl());
            repo.setSshUrl(project.getSshUrl());
            repo.setDefaultBranch(project.getDefaultBranch());
            repo.setPlatform("gitlab");
            repo.setEnabled(true);

            try {
                gitRepositoryService.create(repo);
            } catch (Exception e) {
                // Ignore duplicates or log
                System.err.println("Skipping duplicate or failed repo: " + project.getName() + " " + e.getMessage());
            }
        }
        return ResponseEntity.ok().build();
    }
}
