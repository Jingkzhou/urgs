package com.example.urgs_api.version.service;

import com.example.urgs_api.version.dto.GitBranch;
import com.example.urgs_api.version.dto.GitTag;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.dto.GitFileContent;
import com.example.urgs_api.version.dto.GitFileEntry;
import com.example.urgs_api.version.entity.GitRepository;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;

/**
 * Git 平台 API 服务
 * 支持 Gitee、GitHub、GitLab
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class GitPlatformService {

    private final GitRepositoryService gitRepositoryService;
    private final ObjectMapper objectMapper;

    private static final HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .build();

    /**
     * 获取文件树
     */
    public List<GitFileEntry> getFileTree(Long repoId, String ref, String path) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        if (ref == null || ref.isEmpty()) {
            ref = repo.getDefaultBranch() != null ? repo.getDefaultBranch() : "master";
        }
        if (path == null) {
            path = "";
        }

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeFileTree(repo, ref, path);
                case "github" -> getGitHubFileTree(repo, ref, path);
                case "gitlab" -> getGitLabFileTree(repo, ref, path);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取文件树失败: repoId={}, ref={}, path={}", repoId, ref, path, e);
            throw new RuntimeException("获取文件树失败: " + e.getMessage());
        }
    }

    /**
     * 获取分支列表
     */
    public List<GitBranch> getBranches(Long repoId) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeBranches(repo);
                case "github" -> getGitHubBranches(repo);
                case "gitlab" -> getGitLabBranches(repo);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取分支列表失败: repoId={}", repoId, e);
            throw new RuntimeException("获取分支列表失败: " + e.getMessage());
        }
    }

    /**
     * 获取提交列表
     */
    public List<GitCommit> getCommits(Long repoId, String ref, Integer page, Integer perPage) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        if (ref == null || ref.isEmpty()) {
            ref = repo.getDefaultBranch() != null ? repo.getDefaultBranch() : "master";
        }
        if (page == null || page < 1)
            page = 1;
        if (perPage == null || perPage < 1)
            perPage = 20;

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeCommits(repo, ref, page, perPage);
                case "github" -> getGitHubCommits(repo, ref, page, perPage);
                case "gitlab" -> getGitLabCommits(repo, ref, page, perPage);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取提交列表失败: repoId={}, ref={}", repoId, ref, e);
            throw new RuntimeException("获取提交列表失败: " + e.getMessage());
        }
    }

    /**
     * 获取提交详情 (包含 Diff)
     */
    public GitCommit getCommitDetail(Long repoId, String sha) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeCommitDetail(repo, sha);
                case "github" -> getGitHubCommitDetail(repo, sha);
                case "gitlab" -> getGitLabCommitDetail(repo, sha);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取提交详情失败: repoId={}, sha={}", repoId, sha, e);
            throw new RuntimeException("获取提交详情失败: " + e.getMessage());
        }
    }

    /**
     * 获取最新提交
     */
    public GitCommit getLatestCommit(Long repoId, String ref) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        if (ref == null || ref.isEmpty()) {
            ref = repo.getDefaultBranch() != null ? repo.getDefaultBranch() : "master";
        }

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeLatestCommit(repo, ref);
                case "github" -> getGitHubLatestCommit(repo, ref);
                case "gitlab" -> getGitLabLatestCommit(repo, ref);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取最新提交失败: repoId={}, ref={}", repoId, ref, e);
            throw new RuntimeException("获取最新提交失败: " + e.getMessage());
        }
    }

    /**
     * 获取文件内容
     */
    public GitFileContent getFileContent(Long repoId, String ref, String path) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        if (ref == null || ref.isEmpty()) {
            ref = repo.getDefaultBranch() != null ? repo.getDefaultBranch() : "master";
        }

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeFileContent(repo, ref, path);
                case "github" -> getGitHubFileContent(repo, ref, path);
                case "gitlab" -> getGitLabFileContent(repo, ref, path);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取文件内容失败: repoId={}, ref={}, path={}", repoId, ref, path, e);
            throw new RuntimeException("获取文件内容失败: " + e.getMessage());
        }
    }

    /**
     * 创建分支
     */
    public void createBranch(Long repoId, String name, String ref, String userToken) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = (userToken != null && !userToken.isEmpty()) ? userToken : repo.getAccessToken();
        if (effectiveToken == null || effectiveToken.isEmpty()) {
            throw new RuntimeException("No access token available (user or repo)");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> createGiteeBranch(repo, name, ref, effectiveToken);
                case "github" -> createGitHubBranch(repo, name, ref, effectiveToken);
                case "gitlab" -> createGitLabBranch(repo, name, ref, effectiveToken);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("创建分支失败: repoId={}, name={}, ref={}", repoId, name, ref, e);
            throw new RuntimeException("创建分支失败: " + e.getMessage());
        }
    }

    /**
     * 删除分支
     */
    public void deleteBranch(Long repoId, String name, String userToken) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = (userToken != null && !userToken.isEmpty()) ? userToken : repo.getAccessToken();

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> deleteGiteeBranch(repo, name, effectiveToken);
                case "github" -> deleteGitHubBranch(repo, name, effectiveToken);
                case "gitlab" -> deleteGitLabBranch(repo, name, effectiveToken);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("删除分支失败: repoId={}, name={}", repoId, name, e);
            throw new RuntimeException("删除分支失败: " + e.getMessage());
        }
    }

    /**
     * 获取标签列表
     */
    public List<GitTag> getTags(Long repoId) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteeTags(repo);
                case "github" -> getGitHubTags(repo);
                case "gitlab" -> getGitLabTags(repo);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取标签列表失败: repoId={}", repoId, e);
            throw new RuntimeException("获取标签列表失败: " + e.getMessage());
        }
    }

    // ==================== Gitee ====================

    private List<GitFileEntry> getGiteeFileTree(GitRepository repo, String ref, String path) throws Exception {
        // Gitee API: 获取仓库内容
        // https://gitee.com/api/v5/repos/{owner}/{repo}/contents/{path}?ref={ref}&access_token={token}
        String fullName = repo.getFullName(); // owner/repo
        String encodedPath = path.isEmpty() ? "" : "/" + path;
        String url = String.format("https://gitee.com/api/v5/repos/%s/contents%s?ref=%s", fullName, encodedPath, ref);

        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);
        List<GitFileEntry> entries = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                entries.add(GitFileEntry.builder()
                        .name(node.path("name").asText())
                        .path(node.path("path").asText())
                        .type(node.path("type").asText().equals("dir") ? "dir" : "file")
                        .size(node.path("size").asLong(0))
                        .sha(node.path("sha").asText())
                        .build());
            }
        }

        // 排序：目录在前，文件在后
        entries.sort((a, b) -> {
            if (a.getType().equals(b.getType())) {
                return a.getName().compareToIgnoreCase(b.getName());
            }
            return a.getType().equals("dir") ? -1 : 1;
        });

        return entries;
    }

    private List<GitBranch> getGiteeBranches(GitRepository repo) throws Exception {
        List<GitBranch> allBranches = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("https://gitee.com/api/v5/repos/%s/branches?page=%d&per_page=%d",
                    repo.getFullName(), page, perPage);
            if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
                url += "&access_token=" + repo.getAccessToken();
            }

            JsonNode response = httpGet(url);

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                allBranches.add(GitBranch.builder()
                        .name(node.path("name").asText())
                        .isProtected(node.path("protected").asBoolean(false))
                        .commitSha(node.path("commit").path("sha").asText())
                        .isDefault(node.path("name").asText().equals(repo.getDefaultBranch()))
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allBranches;
    }

    private GitCommit getGiteeLatestCommit(GitRepository repo, String ref) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/commits?sha=%s&per_page=1", repo.getFullName(),
                ref);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);

        if (response.isArray() && response.size() > 0) {
            JsonNode commit = response.get(0);
            JsonNode commitData = commit.path("commit");
            JsonNode author = commitData.path("author");

            // 获取提交总数
            long totalCommits = getGiteeCommitCount(repo, ref);

            return GitCommit.builder()
                    .sha(commit.path("sha").asText().substring(0, 7))
                    .fullSha(commit.path("sha").asText())
                    .message(commitData.path("message").asText())
                    .authorName(author.path("name").asText())
                    .authorEmail(author.path("email").asText())
                    .authorAvatar(commit.path("author").path("avatar_url").asText())
                    .committedAt(author.path("date").asText())
                    .totalCommits(totalCommits)
                    .build();
        }

        return null;
    }

    private long getGiteeCommitCount(GitRepository repo, String ref) {
        try {
            // Gitee 没有直接的 commit count API，需要通过 HEAD 请求获取 Link header
            // 简化处理：返回一个估算值或使用分页查询
            String url = String.format("https://gitee.com/api/v5/repos/%s/commits?sha=%s&per_page=1&page=1",
                    repo.getFullName(), ref);
            if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
                url += "&access_token=" + repo.getAccessToken();
            }
            // 实际实现中可以解析 Link header 获取总数
            // 这里返回一个占位值
            return 0;
        } catch (Exception e) {
            return 0;
        }
    }

    private List<GitCommit> getGiteeCommits(GitRepository repo, String ref, Integer page, Integer perPage)
            throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/commits?sha=%s&page=%d&per_page=%d",
                repo.getFullName(), ref, page, perPage);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);
        List<GitCommit> commits = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode commit : response) {
                JsonNode commitData = commit.path("commit");
                JsonNode author = commitData.path("author");
                commits.add(GitCommit.builder()
                        .sha(commit.path("sha").asText().substring(0, 7))
                        .fullSha(commit.path("sha").asText())
                        .message(commitData.path("message").asText())
                        .authorName(author.path("name").asText())
                        .authorEmail(author.path("email").asText())
                        .authorAvatar(commit.path("author").path("avatar_url").asText())
                        .committedAt(author.path("date").asText())
                        .build());
            }
        }
        return commits;
    }

    private GitCommit getGiteeCommitDetail(GitRepository repo, String sha) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/commits/%s", repo.getFullName(), sha);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "?access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);

        JsonNode commitData = response.path("commit");
        JsonNode author = commitData.path("author");
        JsonNode files = response.path("files");

        List<GitCommitDiff> diffs = new ArrayList<>();
        if (files.isArray()) {
            for (JsonNode file : files) {
                diffs.add(GitCommitDiff.builder()
                        .newPath(file.path("filename").asText())
                        .oldPath(file.path("filename").asText())
                        .status(file.path("status").asText())
                        .additions(file.path("additions").asInt())
                        .deletions(file.path("deletions").asInt())
                        .diff(file.path("patch").asText())
                        .build());
            }
        }

        return GitCommit.builder()
                .sha(response.path("sha").asText().substring(0, 7))
                .fullSha(response.path("sha").asText())
                .message(commitData.path("message").asText())
                .authorName(author.path("name").asText())
                .authorEmail(author.path("email").asText())
                .authorAvatar(response.path("author").path("avatar_url").asText())
                .committedAt(author.path("date").asText())
                .totalCommits(0L)
                .diffs(diffs)
                .build();
    }

    private GitFileContent getGiteeFileContent(GitRepository repo, String ref, String path) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/contents/%s?ref=%s",
                repo.getFullName(), path, ref);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);

        String content = response.path("content").asText();
        // Gitee 返回 base64 编码的内容
        if (content != null && !content.isEmpty()) {
            content = new String(java.util.Base64.getDecoder().decode(content.replaceAll("\\s", "")));
        }

        return GitFileContent.builder()
                .name(response.path("name").asText())
                .path(response.path("path").asText())
                .size(response.path("size").asLong())
                .content(content)
                .encoding(response.path("encoding").asText())
                .sha(response.path("sha").asText())
                .language(getLanguageFromPath(path))
                .build();
    }

    private void createGiteeBranch(GitRepository repo, String branchName, String refs, String token) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/branches", repo.getFullName());
        // 在 body 中使用提供的 token
        String body = String.format("{\"access_token\":\"%s\",\"branch_name\":\"%s\",\"refs\":\"%s\"}",
                token, branchName, refs);

        httpPost(url, body, null, null);
    }

    private void deleteGiteeBranch(GitRepository repo, String branchName, String token) throws Exception {
        // Gitee API V5 没有公开的删除分支接口
        // 只有移除分支保护的接口 (/branches/{branch}/protection)
        // 参考: https://gitee.com/api/v5/swagger - 没有 DELETE
        // /repos/{owner}/{repo}/branches/{branch} 端点.
        throw new RuntimeException("Gitee 平台 API 暂不支持通过 API 删除分支，请在 Gitee 网页端手动删除。");
    }

    private List<GitTag> getGiteeTags(GitRepository repo) throws Exception {
        List<GitTag> allTags = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("https://gitee.com/api/v5/repos/%s/tags?page=%d&per_page=%d",
                    repo.getFullName(), page, perPage);

            if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
                url += "&access_token=" + repo.getAccessToken();
            }

            JsonNode response = httpGet(url);

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                JsonNode commit = node.path("commit");
                allTags.add(GitTag.builder()
                        .name(node.path("name").asText())
                        .message(node.path("message").asText())
                        .commitSha(commit.path("sha").asText())
                        .commitMessage(commit.path("message").asText())
                        .taggerName(commit.path("author").path("name").asText())
                        .taggerDate(commit.path("author").path("date").asText())
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allTags;
    }

    // ==================== GitHub ====================

    private List<GitFileEntry> getGitHubFileTree(GitRepository repo, String ref, String path) throws Exception {
        String fullName = repo.getFullName();
        String encodedPath = path.isEmpty() ? "" : "/" + path;
        String url = String.format("https://api.github.com/repos/%s/contents%s?ref=%s", fullName, encodedPath, ref);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");
        List<GitFileEntry> entries = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                entries.add(GitFileEntry.builder()
                        .name(node.path("name").asText())
                        .path(node.path("path").asText())
                        .type(node.path("type").asText().equals("dir") ? "dir" : "file")
                        .size(node.path("size").asLong(0))
                        .sha(node.path("sha").asText())
                        .build());
            }
        }

        entries.sort((a, b) -> {
            if (a.getType().equals(b.getType())) {
                return a.getName().compareToIgnoreCase(b.getName());
            }
            return a.getType().equals("dir") ? -1 : 1;
        });

        return entries;
    }

    private List<GitBranch> getGitHubBranches(GitRepository repo) throws Exception {
        List<GitBranch> allBranches = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("https://api.github.com/repos/%s/branches?page=%d&per_page=%d",
                    repo.getFullName(), page, perPage);

            JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                allBranches.add(GitBranch.builder()
                        .name(node.path("name").asText())
                        .isProtected(node.path("protected").asBoolean(false))
                        .commitSha(node.path("commit").path("sha").asText())
                        .isDefault(node.path("name").asText().equals(repo.getDefaultBranch()))
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allBranches;
    }

    private GitCommit getGitHubLatestCommit(GitRepository repo, String ref) throws Exception {
        String url = String.format("https://api.github.com/repos/%s/commits?sha=%s&per_page=1", repo.getFullName(),
                ref);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

        if (response.isArray() && response.size() > 0) {
            JsonNode commit = response.get(0);
            JsonNode commitData = commit.path("commit");
            JsonNode author = commitData.path("author");

            return GitCommit.builder()
                    .sha(commit.path("sha").asText().substring(0, 7))
                    .fullSha(commit.path("sha").asText())
                    .message(commitData.path("message").asText())
                    .authorName(author.path("name").asText())
                    .authorEmail(author.path("email").asText())
                    .authorAvatar(commit.path("author").path("avatar_url").asText())
                    .committedAt(author.path("date").asText())
                    .totalCommits(0L)
                    .build();
        }

        return null;
    }

    private List<GitCommit> getGitHubCommits(GitRepository repo, String ref, Integer page, Integer perPage)
            throws Exception {
        String url = String.format("https://api.github.com/repos/%s/commits?sha=%s&page=%d&per_page=%d",
                repo.getFullName(), ref, page, perPage);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");
        List<GitCommit> commits = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode commit : response) {
                JsonNode commitData = commit.path("commit");
                JsonNode author = commitData.path("author");
                commits.add(GitCommit.builder()
                        .sha(commit.path("sha").asText().substring(0, 7))
                        .fullSha(commit.path("sha").asText())
                        .message(commitData.path("message").asText())
                        .authorName(author.path("name").asText())
                        .authorEmail(author.path("email").asText())
                        .authorAvatar(commit.path("author").path("avatar_url").asText())
                        .committedAt(author.path("date").asText())
                        .build());
            }
        }
        return commits;
    }

    private GitCommit getGitHubCommitDetail(GitRepository repo, String sha) throws Exception {
        String url = String.format("https://api.github.com/repos/%s/commits/%s", repo.getFullName(), sha);
        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

        JsonNode commitData = response.path("commit");
        JsonNode author = commitData.path("author");
        JsonNode files = response.path("files");

        List<GitCommitDiff> diffs = new ArrayList<>();
        if (files.isArray()) {
            for (JsonNode file : files) {
                diffs.add(GitCommitDiff.builder()
                        .newPath(file.path("filename").asText())
                        .oldPath(file.path("filename").asText())
                        .status(file.path("status").asText())
                        .additions(file.path("additions").asInt())
                        .deletions(file.path("deletions").asInt())
                        .diff(file.path("patch").asText())
                        .build());
            }
        }

        return GitCommit.builder()
                .sha(response.path("sha").asText().substring(0, 7))
                .fullSha(response.path("sha").asText())
                .message(commitData.path("message").asText())
                .authorName(author.path("name").asText())
                .authorEmail(author.path("email").asText())
                .authorAvatar(response.path("author").path("avatar_url").asText())
                .committedAt(author.path("date").asText())
                .diffs(diffs)
                .build();
    }

    private GitFileContent getGitHubFileContent(GitRepository repo, String ref, String path) throws Exception {
        String url = String.format("https://api.github.com/repos/%s/contents/%s?ref=%s",
                repo.getFullName(), path, ref);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

        String content = response.path("content").asText();
        if (content != null && !content.isEmpty()) {
            content = new String(java.util.Base64.getDecoder().decode(content.replaceAll("\\s", "")));
        }

        return GitFileContent.builder()
                .name(response.path("name").asText())
                .path(response.path("path").asText())
                .size(response.path("size").asLong())
                .content(content)
                .encoding(response.path("encoding").asText())
                .sha(response.path("sha").asText())
                .language(getLanguageFromPath(path))
                .build();
    }

    private void createGitHubBranch(GitRepository repo, String branchName, String sha, String token) throws Exception {
        String url = String.format("https://api.github.com/repos/%s/git/refs", repo.getFullName());
        String body = String.format("{\"ref\":\"refs/heads/%s\",\"sha\":\"%s\"}", branchName, sha);

        httpPost(url, body, token, "Bearer");
    }

    private void deleteGitHubBranch(GitRepository repo, String branchName, String token) throws Exception {
        String url = String.format("https://api.github.com/repos/%s/git/refs/heads/%s", repo.getFullName(), branchName);

        httpDelete(url, token, "Bearer");
    }

    private List<GitTag> getGitHubTags(GitRepository repo) throws Exception {
        List<GitTag> allTags = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("https://api.github.com/repos/%s/tags?page=%d&per_page=%d",
                    repo.getFullName(), page, perPage);

            JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                JsonNode commit = node.path("commit");
                allTags.add(GitTag.builder()
                        .name(node.path("name").asText())
                        .commitSha(commit.path("sha").asText())
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allTags;
    }

    // ==================== GitLab ====================

    private GitFileContent getGitLabFileContent(GitRepository repo, String ref, String path) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String encodedPath = java.net.URLEncoder.encode(path, "UTF-8");
        String url = String.format("%s/projects/%s/repository/files/%s?ref=%s",
                apiBase,
                projectId, encodedPath, ref);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");

        String content = response.path("content").asText();
        if (content != null && !content.isEmpty()) {
            content = new String(java.util.Base64.getDecoder().decode(content.replaceAll("\\s", "")));
        }

        return GitFileContent.builder()
                .name(response.path("file_name").asText())
                .path(response.path("file_path").asText())
                .size(response.path("size").asLong())
                .content(content)
                .encoding(response.path("encoding").asText())
                .sha(response.path("content_sha256").asText())
                .language(getLanguageFromPath(path))
                .build();
    }

    private List<GitFileEntry> getGitLabFileTree(GitRepository repo, String ref, String path) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        // GitLab 需要 project ID，这里使用 URL 编码的 fullName
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/tree?ref=%s&path=%s",
                apiBase,
                projectId, ref, path.isEmpty() ? "" : path);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");
        List<GitFileEntry> entries = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                entries.add(GitFileEntry.builder()
                        .name(node.path("name").asText())
                        .path(node.path("path").asText())
                        .type(node.path("type").asText().equals("tree") ? "dir" : "file")
                        .sha(node.path("id").asText())
                        .build());
            }
        }

        entries.sort((a, b) -> {
            if (a.getType().equals(b.getType())) {
                return a.getName().compareToIgnoreCase(b.getName());
            }
            return a.getType().equals("dir") ? -1 : 1;
        });

        return entries;
    }

    private List<GitBranch> getGitLabBranches(GitRepository repo) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        List<GitBranch> allBranches = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("%s/projects/%s/repository/branches?page=%d&per_page=%d",
                    apiBase,
                    projectId, page, perPage);

            JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                JsonNode commit = node.path("commit");
                allBranches.add(GitBranch.builder()
                        .name(node.path("name").asText())
                        .isProtected(node.path("protected").asBoolean(false))
                        .commitSha(commit.path("id").asText())
                        .isDefault(node.path("default").asBoolean(false))
                        .lastCommitDate(commit.path("committed_date").asText())
                        .lastCommitAuthor(commit.path("author_name").asText())
                        .lastCommitMessage(commit.path("message").asText())
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allBranches;
    }

    public List<com.example.urgs_api.version.dto.GitProjectVO> getGitLabProjects(String accessToken) throws Exception {
        // Fetch user's projects (membership=true to include shared projects)
        // Only return projects the user is a member of
        List<com.example.urgs_api.version.dto.GitProjectVO> allProjects = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format(
                    "https://gitlab.com/api/v4/projects?membership=true&simple=true&page=%d&per_page=%d", page,
                    perPage);
            JsonNode response = httpGetWithAuth(url, accessToken, "PRIVATE-TOKEN");

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                allProjects.add(com.example.urgs_api.version.dto.GitProjectVO.builder()
                        .id(node.path("id").asText())
                        .name(node.path("name").asText())
                        .pathWithNamespace(node.path("path_with_namespace").asText())
                        .description(node.path("description").asText())
                        .webUrl(node.path("web_url").asText())
                        .cloneUrl(node.path("http_url_to_repo").asText())
                        .sshUrl(node.path("ssh_url_to_repo").asText())
                        .defaultBranch(node.path("default_branch").asText("master"))
                        .visibility(node.path("visibility").asText())
                        .lastActivityAt(node.path("last_activity_at").asText())
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }
        return allProjects;
    }

    private GitCommit getGitLabLatestCommit(GitRepository repo, String ref) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/commits?ref_name=%s&per_page=1",
                apiBase,
                projectId, ref);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");

        if (response.isArray() && response.size() > 0) {
            JsonNode commit = response.get(0);

            return GitCommit.builder()
                    .sha(commit.path("short_id").asText())
                    .fullSha(commit.path("id").asText())
                    .message(commit.path("message").asText())
                    .authorName(commit.path("author_name").asText())
                    .authorEmail(commit.path("author_email").asText())
                    .authorAvatar(commit.path("author_avatar").asText())
                    .committedAt(commit.path("committed_date").asText())
                    .totalCommits(0L)
                    .build();
        }

        return null;
    }

    private List<GitCommit> getGitLabCommits(GitRepository repo, String ref, Integer page, Integer perPage)
            throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/commits?ref_name=%s&page=%d&per_page=%d",
                apiBase, projectId, ref, page, perPage);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");
        List<GitCommit> commits = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode commit : response) {
                commits.add(GitCommit.builder()
                        .sha(commit.path("short_id").asText())
                        .fullSha(commit.path("id").asText())
                        .message(commit.path("message").asText())
                        .authorName(commit.path("author_name").asText())
                        .authorEmail(commit.path("author_email").asText())
                        .authorAvatar(null)
                        .committedAt(commit.path("committed_date").asText())
                        .build());
            }
        }
        return commits;
    }

    private GitCommit getGitLabCommitDetail(GitRepository repo, String sha) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // Get Commit Info
        String infoUrl = String.format("%s/projects/%s/repository/commits/%s", apiBase, projectId, sha);
        JsonNode commit = httpGetWithAuth(infoUrl, repo.getAccessToken(), "PRIVATE-TOKEN");

        // Get Diffs
        String diffUrl = String.format("%s/projects/%s/repository/commits/%s/diff", apiBase, projectId, sha);
        JsonNode diffsNode = httpGetWithAuth(diffUrl, repo.getAccessToken(), "PRIVATE-TOKEN");

        List<GitCommitDiff> diffs = new ArrayList<>();
        if (diffsNode.isArray()) {
            for (JsonNode file : diffsNode) {
                diffs.add(GitCommitDiff.builder()
                        .newPath(file.path("new_path").asText())
                        .oldPath(file.path("old_path").asText())
                        .newFile(file.path("new_file").asBoolean())
                        .renamedFile(file.path("renamed_file").asBoolean())
                        .deletedFile(file.path("deleted_file").asBoolean())
                        .diff(file.path("diff").asText())
                        .build());
            }
        }

        return GitCommit.builder()
                .sha(commit.path("short_id").asText())
                .fullSha(commit.path("id").asText())
                .message(commit.path("message").asText())
                .authorName(commit.path("author_name").asText())
                .authorEmail(commit.path("author_email").asText())
                .committedAt(commit.path("committed_date").asText())
                .diffs(diffs)
                .build();
    }

    private void createGitLabBranch(GitRepository repo, String branchName, String ref, String token) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/branches", apiBase, projectId);

        String body = String.format("{\"branch\":\"%s\",\"ref\":\"%s\"}", branchName, ref);

        httpPost(url, body, token, "PRIVATE-TOKEN");
    }

    private void deleteGitLabBranch(GitRepository repo, String branchName, String token) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String branch = java.net.URLEncoder.encode(branchName, "UTF-8");
        String url = String.format("%s/projects/%s/repository/branches/%s", apiBase, projectId, branch);

        httpDelete(url, token, "PRIVATE-TOKEN");
    }

    private List<GitTag> getGitLabTags(GitRepository repo) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        List<GitTag> allTags = new ArrayList<>();
        int page = 1;
        int perPage = 100;

        while (true) {
            String url = String.format("%s/projects/%s/repository/tags?page=%d&per_page=%d",
                    apiBase, projectId, page, perPage);

            JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");

            if (!response.isArray() || response.isEmpty()) {
                break;
            }

            for (JsonNode node : response) {
                JsonNode commit = node.path("commit");
                allTags.add(GitTag.builder()
                        .name(node.path("name").asText())
                        .message(node.path("message").asText())
                        .commitSha(commit.path("id").asText())
                        .commitMessage(commit.path("message").asText())
                        .taggerName(commit.path("author_name").asText())
                        .taggerDate(commit.path("committed_date").asText())
                        .build());
            }

            if (response.size() < perPage) {
                break;
            }
            page++;
        }

        return allTags;
    }

    private String getGitLabProjectId(GitRepository repo) throws Exception {
        String fullName = resolveRepoFullName(repo);
        return java.net.URLEncoder.encode(fullName, "UTF-8");
    }

    private String resolveRepoFullName(GitRepository repo) {
        String fullName = repo.getFullName();
        if (fullName != null) {
            fullName = fullName.trim();
        }
        if (fullName != null && !fullName.isEmpty()) {
            String fromInput = parseFullNameFromCloneUrl(fullName);
            return fromInput != null ? fromInput : fullName;
        }
        String fromClone = parseFullNameFromCloneUrl(repo.getCloneUrl());
        if (fromClone != null) {
            log.warn("仓库全名为空，使用仓库地址解析: {}", fromClone);
            return fromClone;
        }
        throw new RuntimeException("仓库全名为空或无法从仓库地址解析");
    }

    private String parseFullNameFromCloneUrl(String value) {
        if (value == null) {
            return null;
        }
        String trimmed = value.trim();
        if (trimmed.isEmpty()) {
            return null;
        }
        if (trimmed.contains("://")) {
            try {
                URI uri = URI.create(trimmed);
                return normalizeRepoPath(uri.getPath());
            } catch (IllegalArgumentException e) {
                log.warn("解析仓库地址失败: {}", trimmed, e);
                return null;
            }
        }
        int colonIndex = trimmed.indexOf(':');
        int atIndex = trimmed.indexOf('@');
        if (colonIndex > -1 && (atIndex == -1 || colonIndex > atIndex)) {
            return normalizeRepoPath(trimmed.substring(colonIndex + 1));
        }
        return normalizeRepoPath(trimmed);
    }

    private String normalizeRepoPath(String path) {
        if (path == null) {
            return null;
        }
        String cleaned = path.trim();
        while (cleaned.startsWith("/")) {
            cleaned = cleaned.substring(1);
        }
        if (cleaned.endsWith(".git")) {
            cleaned = cleaned.substring(0, cleaned.length() - 4);
        }
        return cleaned.isEmpty() ? null : cleaned;
    }

    private String getGitLabApiBase(GitRepository repo) {
        String cloneUrl = repo.getCloneUrl();
        if (cloneUrl == null || cloneUrl.isBlank()) {
            return "https://gitlab.com/api/v4";
        }
        try {
            URI uri = URI.create(cloneUrl);
            if (uri.getHost() == null) {
                return "https://gitlab.com/api/v4";
            }
            String scheme = uri.getScheme() != null ? uri.getScheme() : "https";
            int port = uri.getPort();
            String base = scheme + "://" + uri.getHost() + (port != -1 ? ":" + port : "");
            return base + "/api/v4";
        } catch (IllegalArgumentException e) {
            log.warn("解析 GitLab cloneUrl 失败: {}", cloneUrl, e);
            return "https://gitlab.com/api/v4";
        }
    }

    // ==================== HTTP Helpers ====================

    private JsonNode httpGet(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(30))
                .GET()
                .build();

        HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() >= 400) {
            throw new RuntimeException("HTTP " + response.statusCode() + ": " + response.body());
        }

        return objectMapper.readTree(response.body());
    }

    private JsonNode httpGetWithAuth(String url, String token, String authType) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(30));

        if (token != null && !token.isEmpty()) {
            if ("PRIVATE-TOKEN".equals(authType)) {
                builder.header("PRIVATE-TOKEN", token);
            } else {
                builder.header("Authorization", authType + " " + token);
            }
        }

        HttpResponse<String> response = httpClient.send(builder.GET().build(), HttpResponse.BodyHandlers.ofString());

        if (response.statusCode() >= 400) {
            throw new RuntimeException("HTTP " + response.statusCode() + ": " + response.body());
        }

        return objectMapper.readTree(response.body());
    }

    private void httpPost(String url, String body, String token, String authType) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(30));

        if (token != null && !token.isEmpty()) {
            if (authType == null) {
                // No auth header added
            } else if ("PRIVATE-TOKEN".equals(authType)) {
                builder.header("PRIVATE-TOKEN", token);
            } else {
                builder.header("Authorization", authType + " " + token);
            }
        }

        builder.POST(HttpRequest.BodyPublishers.ofString(body));

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new RuntimeException("HTTP POST " + response.statusCode() + ": " + response.body());
        }
    }

    private void httpDelete(String url, String token, String authType) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Accept", "application/json")
                .header("Content-Type", "application/json;charset=UTF-8")
                .timeout(Duration.ofSeconds(30))
                .version(HttpClient.Version.HTTP_1_1); // Force HTTP 1.1 to avoid potential HTTP/2 issues with DELETE

        if (token != null && !token.isEmpty()) {
            if ("PRIVATE-TOKEN".equals(authType)) {
                builder.header("PRIVATE-TOKEN", token);
            } else {
                builder.header("Authorization", authType + " " + token);
            }
        }

        builder.DELETE();

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            log.error("HTTP DELETE Error: Status={}, Body={}", response.statusCode(), response.body());
            throw new RuntimeException("HTTP DELETE " + response.statusCode() + ": " + response.body());
        }
    }

    /**
     * 根据文件路径获取语言类型（用于语法高亮）
     */
    private String getLanguageFromPath(String path) {
        if (path == null || path.isEmpty())
            return "text";

        String ext = path.contains(".") ? path.substring(path.lastIndexOf('.') + 1).toLowerCase() : "";

        return switch (ext) {
            case "java" -> "java";
            case "js", "jsx" -> "javascript";
            case "ts", "tsx" -> "typescript";
            case "py" -> "python";
            case "sql" -> "sql";
            case "json" -> "json";
            case "xml" -> "xml";
            case "html", "htm" -> "html";
            case "css", "scss", "less" -> "css";
            case "md", "markdown" -> "markdown";
            case "yaml", "yml" -> "yaml";
            case "sh", "bash" -> "bash";
            case "go" -> "go";
            case "rs" -> "rust";
            case "rb" -> "ruby";
            case "php" -> "php";
            case "c", "h" -> "c";
            case "cpp", "hpp", "cc" -> "cpp";
            case "vue" -> "vue";
            case "properties" -> "properties";
            default -> "text";
        };
    }
}
