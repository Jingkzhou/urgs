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
import java.io.InputStream;
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

    private HttpClient httpClient = HttpClient.newBuilder()
            .connectTimeout(Duration.ofSeconds(10))
            .followRedirects(HttpClient.Redirect.NORMAL)
            .version(HttpClient.Version.HTTP_1_1)
            .build();

    // For testing
    public void setHttpClient(HttpClient httpClient) {
        this.httpClient = httpClient;
    }

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
     * 创建标签
     */
    public void createTag(Long repoId, String name, String ref, String message, String userToken) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = (userToken != null && !userToken.isEmpty()) ? userToken : repo.getAccessToken();
        if (effectiveToken == null || effectiveToken.isEmpty()) {
            throw new RuntimeException("No access token available (user or repo)");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> createGiteeTag(repo, name, ref, message, effectiveToken);
                case "github" -> createGitHubTag(repo, name, ref, message, effectiveToken);
                case "gitlab" -> createGitLabTag(repo, name, ref, message, effectiveToken);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("创建标签失败: repoId={}, name={}, ref={}", repoId, name, ref, e);
            throw new RuntimeException("创建标签失败: " + e.getMessage());
        }
    }

    /**
     * 下载归档文件 (Zip)
     */
    public InputStream downloadArchive(Long repoId, String ref) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = repo.getAccessToken(); // 目前使用仓库级 Token
        if (effectiveToken == null || effectiveToken.isEmpty()) {
            throw new RuntimeException("仓库访问令牌缺失，无法下载");
        }

        try {
            String url;
            String authHeader = null;
            String authValue = null;

            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> {
                    url = String.format("https://gitee.com/api/v5/repos/%s/zipball?access_token=%s&ref=%s",
                            repo.getFullName(), effectiveToken, ref);
                }
                case "github" -> {
                    url = String.format("https://api.github.com/repos/%s/zipball/%s",
                            repo.getFullName(), ref);
                    authHeader = "Authorization";
                    authValue = "Bearer " + effectiveToken;
                }
                case "gitlab" -> {
                    String apiBase = getGitLabApiBase(repo);
                    String projectId = getGitLabProjectId(repo);
                    url = String.format("%s/projects/%s/repository/archive.zip?sha=%s",
                            apiBase, projectId, ref);
                    authHeader = "PRIVATE-TOKEN";
                    authValue = effectiveToken;
                }
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }

            HttpRequest.Builder builder = HttpRequest.newBuilder()
                    .uri(URI.create(url))
                    .timeout(Duration.ofSeconds(60));

            if (authHeader != null) {
                builder.header(authHeader, authValue);
            }

            HttpResponse<InputStream> response = httpClient.send(builder.GET().build(),
                    HttpResponse.BodyHandlers.ofInputStream());

            if (response.statusCode() >= 400) {
                throw new RuntimeException("HTTP " + response.statusCode() + " while downloading archive");
            }

            return response.body();
        } catch (Exception e) {
            log.error("下载归档失败: repoId={}, ref={}", repoId, ref, e);
            throw new RuntimeException("下载归档失败: " + e.getMessage());
        }
    }

    /**
     * 删除标签
     */
    public void deleteTag(Long repoId, String name, String userToken) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = (userToken != null && !userToken.isEmpty()) ? userToken : repo.getAccessToken();
        if (effectiveToken == null || effectiveToken.isEmpty()) {
            throw new RuntimeException("No access token available (user or repo)");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> deleteGiteeTag(repo, name, effectiveToken);
                case "github" -> deleteGitHubTag(repo, name, effectiveToken);
                case "gitlab" -> deleteGitLabTag(repo, name, effectiveToken);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("删除标签失败: repoId={}, name={}", repoId, name, e);
            throw new RuntimeException("删除标签失败: " + e.getMessage());
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

    /**
     * 获取 Pull Request 列表
     */
    public List<com.example.urgs_api.version.dto.GitPullRequest> getPullRequests(Long repoId, String state,
            Integer page, Integer perPage) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        if (page == null || page < 1)
            page = 1;
        if (perPage == null || perPage < 1)
            perPage = 20;
        if (state == null)
            state = "all";

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteePullRequests(repo, state, page, perPage);
                case "github" -> getGitHubPullRequests(repo, state, page, perPage);
                case "gitlab" -> getGitLabPullRequests(repo, state, page, perPage);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取 PR 列表失败: repoId={}", repoId, e);
            throw new RuntimeException("获取 PR 列表失败: " + e.getMessage());
        }
    }

    /**
     * 获取 Pull Request 详情
     */
    public com.example.urgs_api.version.dto.GitPullRequest getPullRequest(Long repoId, Long number) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteePullRequest(repo, number);
                case "github" -> getGitHubPullRequest(repo, number);
                case "gitlab" -> getGitLabPullRequest(repo, number);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            };
        } catch (Exception e) {
            log.error("获取 PR 详情失败: repoId={}, number={}", repoId, number, e);
            throw new RuntimeException("获取 PR 详情失败: " + e.getMessage());
        }
    }

    /**
     * 创建 Pull Request
     */
    public void createPullRequest(Long repoId, String title, String body, String head, String base, String userToken) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String effectiveToken = (userToken != null && !userToken.isEmpty()) ? userToken : repo.getAccessToken();
        if (effectiveToken == null || effectiveToken.isEmpty()) {
            throw new RuntimeException("No access token available");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> createGiteePullRequest(repo, title, body, head, base, effectiveToken);
                case "github" -> createGitHubPullRequest(repo, title, body, head, base, effectiveToken);
                case "gitlab" -> createGitLabPullRequest(repo, title, body, head, base, effectiveToken);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("创建 PR 失败: repoId={}, title={}", repoId, title, e);
            throw new RuntimeException("创建 PR 失败: " + e.getMessage());
        }
    }

    /**
     * 获取开启状态的 PR 数量 (上限 100)
     */
    public int getOpenPrCount(Long repoId) {
        try {
            List<com.example.urgs_api.version.dto.GitPullRequest> prs = getPullRequests(repoId, "open", 1, 100);
            return prs.size();
        } catch (Exception e) {
            log.warn("Failed to get open PR count for repo {}: {}", repoId, e.getMessage());
            return 0;
        }
    }

    // ==================== PR Extended Operations ====================

    /**
     * 获取 PR 提交列表
     */
    public List<GitCommit> getPullRequestCommits(Long repoId, Long number) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteePullRequestCommits(repo, number);
                case "github" -> getGitHubPullRequestCommits(repo, number);
                case "gitlab" -> getGitLabPullRequestCommits(repo, number);
                default -> new ArrayList<>();
            };
        } catch (Exception e) {
            log.error("获取 PR 提交列表失败: repoId={}, number={}", repoId, number, e);
            throw new RuntimeException("获取 PR 提交列表失败: " + e.getMessage());
        }
    }

    /**
     * 获取 PR 文件变更
     */
    public List<GitCommitDiff> getPullRequestFiles(Long repoId, Long number) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        try {
            return switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> getGiteePullRequestFiles(repo, number);
                case "github" -> getGitHubPullRequestFiles(repo, number);
                case "gitlab" -> getGitLabPullRequestFiles(repo, number);
                default -> new ArrayList<>();
            };
        } catch (Exception e) {
            log.error("获取 PR 文件变更失败: repoId={}, number={}", repoId, number, e);
            throw new RuntimeException("获取 PR 文件变更失败: " + e.getMessage());
        }
    }

    /**
     * 合并 PR
     */
    public void mergePullRequest(Long repoId, Long number, String mergeMethod) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String token = repo.getAccessToken(); // Use repo token
        if (token == null || token.isEmpty()) {
            throw new RuntimeException("Repo token required for merge");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> mergeGiteePullRequest(repo, number, mergeMethod, token);
                case "gitlab" -> mergeGitLabPullRequest(repo, number, mergeMethod, token);
                case "github" -> mergeGitHubPullRequest(repo, number, mergeMethod, token);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("合并 PR 失败: repoId={}, number={}", repoId, number, e);
            throw new RuntimeException("合并 PR 失败: " + e.getMessage());
        }
    }

    /**
     * 关闭 PR
     */
    public void closePullRequest(Long repoId, Long number) {
        GitRepository repo = gitRepositoryService.findById(repoId)
                .orElseThrow(() -> new RuntimeException("仓库不存在: " + repoId));

        String token = repo.getAccessToken(); // Use repo token
        if (token == null || token.isEmpty()) {
            throw new RuntimeException("Repo token required for close");
        }

        try {
            switch (repo.getPlatform().toLowerCase()) {
                case "gitee" -> closeGiteePullRequest(repo, number, token);
                case "gitlab" -> closeGitLabPullRequest(repo, number, token);
                case "github" -> closeGitHubPullRequest(repo, number, token);
                default -> throw new RuntimeException("不支持的平台: " + repo.getPlatform());
            }
        } catch (Exception e) {
            log.error("关闭 PR 失败: repoId={}, number={}", repoId, number, e);
            throw new RuntimeException("关闭 PR 失败: " + e.getMessage());
        }
    }

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

    private List<com.example.urgs_api.version.dto.GitPullRequest> getGiteePullRequests(GitRepository repo, String state,
            Integer page, Integer perPage) throws Exception {
        // Gitee: GET /repos/{owner}/{repo}/pulls
        String url = String.format(
                "https://gitee.com/api/v5/repos/%s/pulls?state=%s&sort=created&direction=desc&page=%d&per_page=%d",
                repo.getFullName(), state, page, perPage);

        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);
        List<com.example.urgs_api.version.dto.GitPullRequest> prs = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                prs.add(mapGiteeToGitPullRequest(node));
            }
        }
        return prs;
    }

    private com.example.urgs_api.version.dto.GitPullRequest getGiteePullRequest(GitRepository repo, Long number)
            throws Exception {
        // Gitee: GET /repos/{owner}/{repo}/pulls/{number}
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls/%s", repo.getFullName(), number);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "&access_token=" + repo.getAccessToken();
        }

        JsonNode response = httpGet(url);
        return mapGiteeToGitPullRequest(response);
    }

    private void createGiteePullRequest(GitRepository repo, String title, String body, String head, String base,
            String token) throws Exception {
        // Gitee: POST /repos/{owner}/{repo}/pulls
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls", repo.getFullName());
        String payload = String.format(
                "{\"access_token\":\"%s\",\"title\":\"%s\",\"body\":\"%s\",\"head\":\"%s\",\"base\":\"%s\"}",
                token, title, body != null ? body : "", head, base);

        httpPost(url, payload, null, null);
    }

    private List<GitCommit> getGiteePullRequestCommits(GitRepository repo, Long number) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls/%d/commits", repo.getFullName(), number);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "?access_token=" + repo.getAccessToken();
        }

        log.info("Fetching PR commits from: {}", url);
        JsonNode response = httpGet(url);
        log.info("PR commits response size: {}", response.size());

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

    private List<GitCommitDiff> getGiteePullRequestFiles(GitRepository repo, Long number) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls/%d/files", repo.getFullName(), number);
        if (repo.getAccessToken() != null && !repo.getAccessToken().isEmpty()) {
            url += "?access_token=" + repo.getAccessToken();
        }
        JsonNode response = httpGet(url);
        List<GitCommitDiff> files = new ArrayList<>();
        if (response.isArray()) {
            for (JsonNode file : response) {
                files.add(GitCommitDiff.builder()
                        .newPath(file.path("filename").asText())
                        .oldPath(file.path("filename").asText())
                        .status(file.path("status").asText())
                        .additions(file.path("additions").asInt())
                        .deletions(file.path("deletions").asInt())
                        .diff(file.path("patch").asText())
                        .build());
            }
        }
        return files;
    }

    private List<GitCommitDiff> getGitHubPullRequestFiles(GitRepository repo, Long number) throws Exception {
        // GitHub: GET /repos/{owner}/{repo}/pulls/{number}/files
        String url = String.format("https://api.github.com/repos/%s/pulls/%s/files", repo.getFullName(), number);
        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");

        List<GitCommitDiff> files = new ArrayList<>();
        if (response.isArray()) {
            for (JsonNode file : response) {
                files.add(GitCommitDiff.builder()
                        .newPath(file.path("filename").asText())
                        .oldPath(file.path("filename").asText()) // GitHub doesn't always provide old path easily in
                                                                 // this view, assuming same unless renamed
                        .status(file.path("status").asText())
                        .additions(file.path("additions").asInt())
                        .deletions(file.path("deletions").asInt())
                        .diff(file.path("patch").asText())
                        .build());
            }
        }
        return files;
    }

    private List<GitCommitDiff> getGitLabPullRequestFiles(GitRepository repo, Long number) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: GET /projects/:id/merge_requests/:merge_request_iid/changes
        String url = String.format("%s/projects/%s/merge_requests/%s/changes", apiBase, projectId, number);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");
        JsonNode changes = response.path("changes");

        List<GitCommitDiff> files = new ArrayList<>();
        if (changes.isArray()) {
            for (JsonNode change : changes) {
                String diff = change.path("diff").asText();
                int additions = 0;
                int deletions = 0;
                if (diff != null && !diff.isEmpty()) {
                    String[] lines = diff.split("\n");
                    for (String line : lines) {
                        if (line.startsWith("+") && !line.startsWith("+++")) {
                            additions++;
                        } else if (line.startsWith("-") && !line.startsWith("---")) {
                            deletions++;
                        }
                    }
                }

                files.add(GitCommitDiff.builder()
                        .newPath(change.path("new_path").asText())
                        .oldPath(change.path("old_path").asText())
                        .newFile(change.path("new_file").asBoolean())
                        .renamedFile(change.path("renamed_file").asBoolean())
                        .deletedFile(change.path("deleted_file").asBoolean())
                        .diff(diff)
                        .additions(additions)
                        .deletions(deletions)
                        .build());
            }
        }
        return files;
    }

    private List<GitCommit> getGitHubPullRequestCommits(GitRepository repo, Long number) throws Exception {
        // GitHub: GET /repos/{owner}/{repo}/pulls/{number}/commits
        String url = String.format("https://api.github.com/repos/%s/pulls/%s/commits", repo.getFullName(), number);
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
                        .authorAvatar(commit.path("author").path("avatar_url").asText()) // GitHub commit author info
                                                                                         // usually has this
                        .committedAt(author.path("date").asText())
                        .build());
            }
        }
        return commits;
    }

    private List<GitCommit> getGitLabPullRequestCommits(GitRepository repo, Long number) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: GET /projects/:id/merge_requests/:merge_request_iid/commits
        String url = String.format("%s/projects/%s/merge_requests/%s/commits", apiBase, projectId, number);

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
                        .committedAt(commit.path("committed_date").asText())
                        .build());
            }
        }
        return commits;
    }

    private void mergeGiteePullRequest(GitRepository repo, Long number, String mergeMethod, String token)
            throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls/%d/merge", repo.getFullName(), number);
        // Gitee properties: access_token, merge_method (merge, squash, rebase)
        String body = String.format("{\"access_token\":\"%s\",\"merge_method\":\"%s\"}", token, mergeMethod);
        httpPut(url, body, null, null);
    }

    private void closeGiteePullRequest(GitRepository repo, Long number, String token) throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/pulls/%d", repo.getFullName(), number);
        String body = String.format("{\"access_token\":\"%s\",\"state\":\"closed\"}", token);
        httpPatch(url, body, null, null);
    }

    private void mergeGitLabPullRequest(GitRepository repo, Long number, String mergeMethod, String token)
            throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: PUT /projects/:id/merge_requests/:merge_request_iid/merge
        String url = String.format("%s/projects/%s/merge_requests/%s/merge", apiBase, projectId, number);

        // Optional: merge_commit_message
        String body = "";
        if (mergeMethod != null && !mergeMethod.isEmpty()) {
            // GitLab supports: should_remove_source_branch, merge_when_pipeline_succeeds,
            // etc.
            // Mapping standard mergeMethod to commit message note or similar if needed.
            // For now, sending empty body or essential params.
            // GitLab API usually accepts empty body for default merge.
        }

        httpPut(url, "{}", token, "PRIVATE-TOKEN");
    }

    private void closeGitLabPullRequest(GitRepository repo, Long number, String token) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: PUT /projects/:id/merge_requests/:merge_request_iid
        String url = String.format("%s/projects/%s/merge_requests/%s", apiBase, projectId, number);

        // to close: state_event=close
        String body = "{\"state_event\":\"close\"}";

        httpPut(url, body, token, "PRIVATE-TOKEN");
    }

    private void mergeGitHubPullRequest(GitRepository repo, Long number, String mergeMethod, String token)
            throws Exception {
        // GitHub: PUT /repos/{owner}/{repo}/pulls/{number}/merge
        String url = String.format("https://api.github.com/repos/%s/pulls/%s/merge", repo.getFullName(), number);

        // mergeMethod: merge, squash, rebase
        String method = (mergeMethod == null || mergeMethod.isEmpty()) ? "merge" : mergeMethod;
        String body = String.format("{\"merge_method\":\"%s\"}", method);

        httpPut(url, body, token, "Bearer");
    }

    private void closeGitHubPullRequest(GitRepository repo, Long number, String token) throws Exception {
        // GitHub: PATCH /repos/{owner}/{repo}/pulls/{number}
        String url = String.format("https://api.github.com/repos/%s/pulls/%s", repo.getFullName(), number);

        String body = "{\"state\":\"closed\"}";

        httpPatch(url, body, token, "Bearer");
    }

    private com.example.urgs_api.version.dto.GitPullRequest mapGiteeToGitPullRequest(JsonNode node) {
        JsonNode user = node.path("user");
        JsonNode head = node.path("head");
        JsonNode base = node.path("base");

        List<com.example.urgs_api.version.dto.GitPullRequest.Label> labels = new ArrayList<>();
        if (node.path("labels").isArray()) {
            for (JsonNode l : node.path("labels")) {
                labels.add(com.example.urgs_api.version.dto.GitPullRequest.Label.builder()
                        .name(l.path("name").asText())
                        .color(l.path("color").asText())
                        .build());
            }
        }

        return com.example.urgs_api.version.dto.GitPullRequest.builder()
                .id(node.path("id").asText())
                .number(node.path("number").asLong())
                .title(node.path("title").asText())
                .state(node.path("state").asText())
                .body(node.path("body").asText())
                .htmlUrl(node.path("html_url").asText())
                .headRef(head.path("ref").asText())
                .headSha(head.path("sha").asText())
                .baseRef(base.path("ref").asText())
                .baseSha(base.path("sha").asText())
                .authorName(user.path("name").asText())
                .authorAvatar(user.path("avatar_url").asText())
                .createdAt(node.path("created_at").asText())
                .updatedAt(node.path("updated_at").asText())
                .closedAt(node.path("closed_at").asText())
                .mergedAt(node.path("merged_at").asText())
                .comments(node.path("comments").asInt(0))
                .commits(node.path("commits").asInt(0))
                .additions(node.path("additions").asInt(0))
                .deletions(node.path("deletions").asInt(0))
                .changedFiles(node.path("changed_files").asInt(0))
                .labels(labels)
                .build();
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

    private List<com.example.urgs_api.version.dto.GitPullRequest> getGitHubPullRequests(GitRepository repo,
            String state, Integer page, Integer perPage) throws Exception {
        // GitHub: https://api.github.com/repos/{owner}/{repo}/pulls
        // state: open, closed, all
        String url = String.format("https://api.github.com/repos/%s/pulls?state=%s&page=%d&per_page=%d",
                repo.getFullName(), state, page, perPage);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");
        List<com.example.urgs_api.version.dto.GitPullRequest> prs = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                prs.add(mapGitHubToGitPullRequest(node));
            }
        }
        return prs;
    }

    private com.example.urgs_api.version.dto.GitPullRequest getGitHubPullRequest(GitRepository repo, Long number)
            throws Exception {
        // GitHub: GET /repos/{owner}/{repo}/pulls/{number}
        String url = String.format("https://api.github.com/repos/%s/pulls/%s", repo.getFullName(), number);
        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "Bearer");
        return mapGitHubToGitPullRequest(response);
    }

    private void createGitHubPullRequest(GitRepository repo, String title, String body, String head, String base,
            String token) throws Exception {
        // GitHub: POST /repos/{owner}/{repo}/pulls
        String url = String.format("https://api.github.com/repos/%s/pulls", repo.getFullName());
        String payload = String.format("{\"title\":\"%s\",\"body\":\"%s\",\"head\":\"%s\",\"base\":\"%s\"}",
                title, body != null ? body : "", head, base);

        httpPost(url, payload, token, "Bearer");
    }

    private com.example.urgs_api.version.dto.GitPullRequest mapGitHubToGitPullRequest(JsonNode node) {
        JsonNode user = node.path("user");
        JsonNode head = node.path("head");
        JsonNode base = node.path("base");

        List<com.example.urgs_api.version.dto.GitPullRequest.Label> labels = new ArrayList<>();
        if (node.path("labels").isArray()) {
            for (JsonNode l : node.path("labels")) {
                labels.add(com.example.urgs_api.version.dto.GitPullRequest.Label.builder()
                        .name(l.path("name").asText())
                        .color(l.path("color").asText())
                        .description(l.path("description").asText())
                        .build());
            }
        }

        return com.example.urgs_api.version.dto.GitPullRequest.builder()
                .id(node.path("id").asText())
                .number(node.path("number").asLong())
                .title(node.path("title").asText())
                .state(node.path("state").asText())
                .body(node.path("body").asText())
                .htmlUrl(node.path("html_url").asText())
                .headRef(head.path("ref").asText())
                .headSha(head.path("sha").asText())
                .baseRef(base.path("ref").asText())
                .baseSha(base.path("sha").asText())
                .authorName(user.path("login").asText())
                .authorAvatar(user.path("avatar_url").asText())
                .createdAt(node.path("created_at").asText())
                .updatedAt(node.path("updated_at").asText())
                .closedAt(node.path("closed_at").asText())
                .mergedAt(node.path("merged_at").asText())
                // GitHub PR list response usually doesn't include details like comments count,
                // additions, deletions
                // These are available in detail response. We map safely.
                .comments(node.path("comments").asInt(0))
                .commits(node.path("commits").asInt(0))
                .additions(node.path("additions").asInt(0))
                .deletions(node.path("deletions").asInt(0))
                .changedFiles(node.path("changed_files").asInt(0))
                .labels(labels)
                .build();
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

    private List<com.example.urgs_api.version.dto.GitPullRequest> getGitLabPullRequests(GitRepository repo,
            String state, Integer page, Integer perPage) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: GET /projects/:id/merge_requests
        // state: opened, closed, locked, merged
        if ("open".equals(state))
            state = "opened"; // Map 'open' to 'opened' for GitLab

        String url = String.format("%s/projects/%s/merge_requests?state=%s&page=%d&per_page=%d",
                apiBase, projectId, state, page, perPage);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");
        List<com.example.urgs_api.version.dto.GitPullRequest> prs = new ArrayList<>();

        if (response.isArray()) {
            for (JsonNode node : response) {
                prs.add(mapGitLabToGitPullRequest(node));
            }
        }
        return prs;
    }

    private com.example.urgs_api.version.dto.GitPullRequest getGitLabPullRequest(GitRepository repo, Long number)
            throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: GET /projects/:id/merge_requests/:merge_request_iid
        String url = String.format("%s/projects/%s/merge_requests/%s",
                apiBase, projectId, number);

        JsonNode response = httpGetWithAuth(url, repo.getAccessToken(), "PRIVATE-TOKEN");
        return mapGitLabToGitPullRequest(response);
    }

    private void createGitLabPullRequest(GitRepository repo, String title, String body, String head, String base,
            String token) throws Exception {
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        // GitLab: POST /projects/:id/merge_requests
        String url = String.format("%s/projects/%s/merge_requests", apiBase, projectId);

        // GitLab requires source_branch and target_branch
        String payload = String.format(
                "{\"source_branch\":\"%s\",\"target_branch\":\"%s\",\"title\":\"%s\",\"description\":\"%s\"}",
                head, base, title, body != null ? body : "");

        httpPost(url, payload, token, "PRIVATE-TOKEN");
    }

    private com.example.urgs_api.version.dto.GitPullRequest mapGitLabToGitPullRequest(JsonNode node) {
        JsonNode author = node.path("author");

        List<com.example.urgs_api.version.dto.GitPullRequest.Label> labels = new ArrayList<>();
        if (node.path("labels").isArray()) {
            for (JsonNode l : node.path("labels")) {
                // GitLab labels in list response are strings
                labels.add(com.example.urgs_api.version.dto.GitPullRequest.Label.builder()
                        .name(l.asText())
                        .build());
            }
        }

        return com.example.urgs_api.version.dto.GitPullRequest.builder()
                .id(node.path("id").asText())
                .number(node.path("iid").asLong())
                .title(node.path("title").asText())
                .state(node.path("state").asText()) // opened, closed, merged, locked
                .body(node.path("description").asText())
                .htmlUrl(node.path("web_url").asText())
                .headRef(node.path("source_branch").asText())
                .headSha(node.path("sha").asText()) // Logic might differ for head SHA access in MR
                .baseRef(node.path("target_branch").asText())
                // .baseSha(...)
                .authorName(author.path("name").asText())
                .authorAvatar(author.path("avatar_url").asText())
                .createdAt(node.path("created_at").asText())
                .updatedAt(node.path("updated_at").asText())
                .closedAt(node.path("closed_at").asText())
                .mergedAt(node.path("merged_at").asText())
                .comments(node.path("user_notes_count").asInt(0))
                // .commits(...)
                // .additions(...)
                // .deletions(...)
                // .changedFiles(...)
                .labels(labels)
                .build();
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
        } catch (Exception e) {
            log.warn("解析 GitLab cloneUrl 失败: {}", cloneUrl, e);
            return "https://gitlab.com/api/v4";
        }
    }

    private void createGiteeTag(GitRepository repo, String tagName, String ref, String message, String token)
            throws Exception {
        String url = String.format("https://gitee.com/api/v5/repos/%s/tags", repo.getFullName());
        // Gitee: POST /repos/{owner}/{repo}/tags
        // refs 是要创建标签的提交 SHA 或者分支名
        String body = String.format("{\"access_token\":\"%s\",\"tag_name\":\"%s\",\"refs\":\"%s\",\"message\":\"%s\"}",
                token, tagName, ref, message == null ? "" : message);
        httpPost(url, body, null, null);
    }

    private void createGitHubTag(GitRepository repo, String tagName, String ref, String message, String token)
            throws Exception {
        // GitHub:
        // https://docs.github.com/en/rest/refs?apiVersion=2022-11-28#create-a-reference
        // 注意：GitHub 创建标签通常需要先创建一个 tag object，或者直接创建一个 ref
        // 简单方式：直接在 refs/tags/ 下创建 ref 指向 commit SHA
        String url = String.format("https://api.github.com/repos/%s/git/refs", repo.getFullName());
        String body = String.format("{\"ref\":\"refs/tags/%s\",\"sha\":\"%s\"}", tagName, ref);
        httpPost(url, body, token, "Bearer");
    }

    private void createGitLabTag(GitRepository repo, String tagName, String ref, String message, String token)
            throws Exception {
        // GitLab: POST /projects/:id/repository/tags
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/tags?tag_name=%s&ref=%s",
                apiBase, projectId, tagName, ref);
        if (message != null && !message.isEmpty()) {
            url += "&message=" + java.net.URLEncoder.encode(message, "UTF-8");
        }
        httpPost(url, "", token, "PRIVATE-TOKEN");
    }

    private void deleteGiteeTag(GitRepository repo, String tagName, String token) throws Exception {
        // Gitee: DELETE /repos/{owner}/{repo}/tags/{tag}
        String url = String.format("https://gitee.com/api/v5/repos/%s/tags/%s?access_token=%s",
                repo.getFullName(), tagName, token);
        httpDelete(url, null, null);
    }

    private void deleteGitHubTag(GitRepository repo, String tagName, String token) throws Exception {
        // GitHub: DELETE /repos/{owner}/{repo}/git/refs/tags/{tag_name}
        String url = String.format("https://api.github.com/repos/%s/git/refs/tags/%s",
                repo.getFullName(), tagName);
        httpDelete(url, token, "Bearer");
    }

    private void deleteGitLabTag(GitRepository repo, String tagName, String token) throws Exception {
        // GitLab: DELETE /projects/:id/repository/tags/:tag_name
        String apiBase = getGitLabApiBase(repo);
        String projectId = getGitLabProjectId(repo);
        String url = String.format("%s/projects/%s/repository/tags/%s",
                apiBase, projectId, java.net.URLEncoder.encode(tagName, "UTF-8"));
        httpDelete(url, token, "PRIVATE-TOKEN");
    }

    // ==================== HTTP Helpers ====================

    private JsonNode httpGet(String url) throws Exception {
        HttpRequest request = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Accept", "application/json")
                .timeout(Duration.ofSeconds(60)) // Increase timeout
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
                .timeout(Duration.ofSeconds(60)); // Increase timeout

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
                .timeout(Duration.ofSeconds(60));

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
                .timeout(Duration.ofSeconds(60));

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

    private void httpPut(String url, String body, String token, String authType) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(60));

        if (token != null && !token.isEmpty()) {
            if ("PRIVATE-TOKEN".equals(authType)) {
                builder.header("PRIVATE-TOKEN", token);
            } else {
                builder.header("Authorization", authType + " " + token);
            }
        }

        builder.PUT(HttpRequest.BodyPublishers.ofString(body));

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new RuntimeException("HTTP PUT " + response.statusCode() + ": " + response.body());
        }
    }

    private void httpPatch(String url, String body, String token, String authType) throws Exception {
        HttpRequest.Builder builder = HttpRequest.newBuilder()
                .uri(URI.create(url))
                .header("Content-Type", "application/json")
                .timeout(Duration.ofSeconds(60));

        if (token != null && !token.isEmpty()) {
            if ("PRIVATE-TOKEN".equals(authType)) {
                builder.header("PRIVATE-TOKEN", token);
            } else {
                builder.header("Authorization", authType + " " + token);
            }
        }

        builder.method("PATCH", HttpRequest.BodyPublishers.ofString(body));

        HttpResponse<String> response = httpClient.send(builder.build(), HttpResponse.BodyHandlers.ofString());
        if (response.statusCode() >= 400) {
            throw new RuntimeException("HTTP PATCH " + response.statusCode() + ": " + response.body());
        }
    }

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
