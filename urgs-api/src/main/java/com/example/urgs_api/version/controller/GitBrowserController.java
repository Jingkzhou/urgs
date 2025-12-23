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
            @RequestParam String ref) {
        gitPlatformService.createBranch(repoId, name, ref);
        return ResponseEntity.ok().build();
    }

    /**
     * 删除分支
     */
    @DeleteMapping("/{repoId}/branches/{name}")
    public ResponseEntity<Void> deleteBranch(
            @PathVariable Long repoId,
            @PathVariable String name) {
        gitPlatformService.deleteBranch(repoId, name);
        return ResponseEntity.ok().build();
    }
}
