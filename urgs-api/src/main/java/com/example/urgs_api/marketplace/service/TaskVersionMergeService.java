package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.marketplace.dto.TaskVersionChangeSnapshotDTO;
import com.example.urgs_api.marketplace.mapper.TaskVersionChangeSnapshotMapper;
import com.example.urgs_api.marketplace.model.TaskVersionChangeSnapshot;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.user.mapper.UserGitIdentityMapper;
import com.example.urgs_api.user.model.UserGitIdentity;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.dto.GitPullRequest;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.service.GitRepositoryService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.BeanUtils;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Set;

@Slf4j
@Service
@RequiredArgsConstructor
public class TaskVersionMergeService {
    private static final String DEFAULT_GIT_PLATFORM = "GITLAB";
    private static final String TARGET_BRANCH = "master";

    private final GitRepositoryService gitRepositoryService;
    private final GitPlatformService gitPlatformService;
    private final UserGitIdentityMapper userGitIdentityMapper;
    private final TaskVersionChangeSnapshotMapper taskVersionChangeSnapshotMapper;
    private final ObjectMapper objectMapper;

    public MergeSummary mergeOpenMasterPullRequests(Work work, WorkTask task, String reviewerId) {
        MergeSummary summary = new MergeSummary();
        String requirementNumber = work == null ? null : trimToNull(work.getRequirementNumber());
        if (!StringUtils.hasText(requirementNumber)) {
            summary.addSkipped("未配置需求编号");
            return summary;
        }

        UserGitIdentity identity = findAssigneeGitIdentity(task);
        if (!hasGitIdentity(identity)) {
            summary.addSkipped("承接人未配置 Git 身份");
            return summary;
        }

        List<String> tokens = buildRequirementTokens(requirementNumber);
        List<GitRepository> repos = gitRepositoryService.findAll().stream()
                .filter(repo -> repo.getId() != null && !Boolean.FALSE.equals(repo.getEnabled()))
                .toList();

        for (GitRepository repo : repos) {
            mergeRepositoryPullRequests(repo, tokens, requirementNumber, work, task, reviewerId, identity, summary);
        }

        if (summary.getMatchedCount() == 0) {
            summary.addSkipped("未找到目标分支为 master 的待合并或已合并 MR");
        }
        return summary;
    }

    public List<TaskVersionChangeSnapshotDTO> listSnapshots(String taskId) {
        if (!StringUtils.hasText(taskId)) {
            return List.of();
        }
        return taskVersionChangeSnapshotMapper.selectList(new LambdaQueryWrapper<TaskVersionChangeSnapshot>()
                        .eq(TaskVersionChangeSnapshot::getTaskId, taskId)
                        .orderByDesc(TaskVersionChangeSnapshot::getCreatedAt)
                        .orderByDesc(TaskVersionChangeSnapshot::getId))
                .stream()
                .map(this::toDto)
                .toList();
    }

    private void mergeRepositoryPullRequests(
            GitRepository repo,
            List<String> tokens,
            String requirementNumber,
            Work work,
            WorkTask task,
            String reviewerId,
            UserGitIdentity identity,
            MergeSummary summary) {
        List<GitPullRequest> pullRequests;
        try {
            pullRequests = gitPlatformService.getPullRequests(repo.getId(), "all", 1, 100);
        } catch (RuntimeException ex) {
            log.warn("任务中心自动合并读取 MR 失败: repoId={}", repo.getId(), ex);
            summary.addSkipped(repoLabel(repo) + " 读取 MR 失败");
            return;
        }

        for (GitPullRequest pullRequest : pullRequests) {
            if (!isRequirementMatched(pullRequest, tokens) || !isMasterTarget(pullRequest)) {
                continue;
            }
            PullRequestMatch match = loadPullRequestMatch(repo, pullRequest, identity);
            if (!match.isMatched()) {
                continue;
            }

            summary.incrementMatchedCount();
            if (!isOpenState(pullRequest) && !isMergedState(pullRequest)) {
                summary.addSkipped(repoLabel(repo) + " !" + pullRequest.getNumber() + " 状态不是待合并或已合并");
                continue;
            }

            List<GitCommitDiff> visibleFiles = loadVisibleFiles(repo, pullRequest, match);
            GitPullRequest snapshotPullRequest = pullRequest;
            try {
                if (isOpenState(pullRequest)) {
                    gitPlatformService.mergePullRequest(repo.getId(), pullRequest.getNumber(), "merge");
                    snapshotPullRequest = refreshPullRequest(repo, pullRequest);
                    summary.addMerged(repoLabel(repo) + " !" + pullRequest.getNumber());
                } else {
                    snapshotPullRequest = refreshPullRequest(repo, pullRequest);
                    summary.addAlreadyMerged(repoLabel(repo) + " !" + pullRequest.getNumber());
                }
                saveSnapshot(
                        requirementNumber,
                        work,
                        task,
                        reviewerId,
                        repo,
                        snapshotPullRequest,
                        match,
                        visibleFiles);
                summary.incrementSnapshotCount();
            } catch (RuntimeException ex) {
                throw new IllegalStateException(
                        "自动合并或固化版本快照失败: " + repoLabel(repo) + " !" + pullRequest.getNumber() + " - " + ex.getMessage(),
                        ex);
            }
        }
    }

    private PullRequestMatch loadPullRequestMatch(GitRepository repo, GitPullRequest pullRequest, UserGitIdentity identity) {
        List<GitCommit> commits = gitPlatformService.getPullRequestCommits(repo.getId(), pullRequest.getNumber());
        if (commits == null) {
            commits = List.of();
        }
        List<GitCommit> matchedCommits = commits.stream()
                .filter(commit -> commitMatchesGitIdentity(commit, identity))
                .toList();
        boolean pullRequestAuthorMatched = pullRequestMatchesGitIdentity(pullRequest, identity);
        String matchSource = matchedCommits.isEmpty() ? "pullRequestAuthor" : "commit";
        return new PullRequestMatch(
                !matchedCommits.isEmpty() || pullRequestAuthorMatched,
                matchSource,
                commits,
                matchedCommits);
    }

    private UserGitIdentity findAssigneeGitIdentity(WorkTask task) {
        Long assigneeId = parseLong(task == null ? null : task.getAssigneeId());
        if (assigneeId == null) {
            return null;
        }
        return userGitIdentityMapper.selectOne(new LambdaQueryWrapper<UserGitIdentity>()
                .eq(UserGitIdentity::getUserId, assigneeId)
                .eq(UserGitIdentity::getPlatform, DEFAULT_GIT_PLATFORM)
                .eq(UserGitIdentity::getEnabled, true)
                .last("LIMIT 1"));
    }

    private List<String> buildRequirementTokens(String requirementNumber) {
        Set<String> tokens = new LinkedHashSet<>();
        if (StringUtils.hasText(requirementNumber)) {
            tokens.add(requirementNumber.trim());
            java.util.regex.Matcher matcher = java.util.regex.Pattern.compile("\\d{6,}").matcher(requirementNumber);
            while (matcher.find()) {
                tokens.add(matcher.group());
            }
        }
        return new ArrayList<>(tokens);
    }

    private boolean isRequirementMatched(GitPullRequest pullRequest, List<String> tokens) {
        String title = pullRequest == null ? null : pullRequest.getTitle();
        return StringUtils.hasText(title) && tokens.stream().anyMatch(title::contains);
    }

    private boolean isMasterTarget(GitPullRequest pullRequest) {
        return TARGET_BRANCH.equals(trimToNull(pullRequest == null ? null : pullRequest.getBaseRef()));
    }

    private boolean isOpenState(GitPullRequest pullRequest) {
        String state = normalizeState(pullRequest == null ? null : pullRequest.getState());
        return "open".equals(state) || "opened".equals(state);
    }

    private boolean isMergedState(GitPullRequest pullRequest) {
        String state = normalizeState(pullRequest == null ? null : pullRequest.getState());
        return "merged".equals(state) || StringUtils.hasText(pullRequest == null ? null : pullRequest.getMergedAt());
    }

    private String normalizeState(String state) {
        if (!StringUtils.hasText(state)) {
            return "";
        }
        return state.trim().toLowerCase(Locale.ROOT);
    }

    private List<GitCommitDiff> loadVisibleFiles(
            GitRepository repo,
            GitPullRequest pullRequest,
            PullRequestMatch match) {
        List<GitCommitDiff> pullRequestFiles = gitPlatformService.getPullRequestFiles(repo.getId(), pullRequest.getNumber());
        if (pullRequestFiles == null) {
            pullRequestFiles = List.of();
        }
        if (match.getMatchedCommits().isEmpty()) {
            return pullRequestFiles;
        }

        List<GitCommitDiff> commitFiles = new ArrayList<>();
        for (GitCommit commit : match.getMatchedCommits()) {
            String sha = StringUtils.hasText(commit.getFullSha()) ? commit.getFullSha() : commit.getSha();
            if (!StringUtils.hasText(sha)) {
                continue;
            }
            try {
                GitCommit detail = gitPlatformService.getCommitDetail(repo.getId(), sha);
                if (detail != null && detail.getDiffs() != null) {
                    commitFiles.addAll(detail.getDiffs());
                }
            } catch (RuntimeException ex) {
                log.warn("任务中心读取提交差异失败，回退到 MR 文件差异: repoId={}, sha={}", repo.getId(), sha, ex);
                return pullRequestFiles;
            }
        }
        return commitFiles.isEmpty() ? pullRequestFiles : dedupeFiles(commitFiles);
    }

    private List<GitCommitDiff> dedupeFiles(List<GitCommitDiff> files) {
        Set<String> seen = new LinkedHashSet<>();
        List<GitCommitDiff> result = new ArrayList<>();
        for (GitCommitDiff file : files) {
            String key = String.join("|",
                    nullToEmpty(file.getOldPath()),
                    nullToEmpty(file.getNewPath()),
                    nullToEmpty(file.getStatus()),
                    nullToEmpty(file.getDiff()));
            if (seen.add(key)) {
                result.add(file);
            }
        }
        return result;
    }

    private GitPullRequest refreshPullRequest(GitRepository repo, GitPullRequest fallback) {
        try {
            return gitPlatformService.getPullRequest(repo.getId(), fallback.getNumber());
        } catch (RuntimeException ex) {
            log.warn("任务中心刷新 MR 详情失败，使用列表数据生成快照: repoId={}, pr={}",
                    repo.getId(), fallback.getNumber(), ex);
            return fallback;
        }
    }

    private void saveSnapshot(
            String requirementNumber,
            Work work,
            WorkTask task,
            String reviewerId,
            GitRepository repo,
            GitPullRequest pullRequest,
            PullRequestMatch match,
            List<GitCommitDiff> visibleFiles) {
        List<GitCommit> visibleCommits = match.getMatchedCommits().isEmpty()
                ? match.getCommits()
                : match.getMatchedCommits();
        DiffStats stats = calculateStats(visibleFiles);
        TaskVersionChangeSnapshot snapshot = findSnapshot(task.getId(), repo.getId(), pullRequest.getNumber());
        if (snapshot == null) {
            snapshot = new TaskVersionChangeSnapshot();
        }
        snapshot.setTaskId(task.getId());
        snapshot.setWorkId(work == null ? task.getWorkId() : work.getId());
        snapshot.setRequirementNumber(requirementNumber);
        snapshot.setAssigneeId(task.getAssigneeId());
        snapshot.setReviewerId(reviewerId);
        snapshot.setRepoId(repo.getId());
        snapshot.setRepoName(repoLabel(repo));
        snapshot.setPrNumber(pullRequest.getNumber());
        snapshot.setPrTitle(pullRequest.getTitle());
        snapshot.setPrUrl(pullRequest.getHtmlUrl());
        snapshot.setSourceBranch(pullRequest.getHeadRef());
        snapshot.setTargetBranch(pullRequest.getBaseRef());
        snapshot.setState(pullRequest.getState());
        snapshot.setMerged(isMergedState(pullRequest));
        snapshot.setMergedAt(pullRequest.getMergedAt());
        snapshot.setMatchSource(match.getMatchSource());
        snapshot.setCommitCount(visibleCommits.size());
        snapshot.setFileCount(visibleFiles.size());
        snapshot.setAdditions(stats.getAdditions());
        snapshot.setDeletions(stats.getDeletions());
        snapshot.setSnapshotJson(writeSnapshotJson(repo, pullRequest, match, visibleCommits, visibleFiles));

        if (snapshot.getId() == null) {
            taskVersionChangeSnapshotMapper.insert(snapshot);
        } else {
            taskVersionChangeSnapshotMapper.updateById(snapshot);
        }
    }

    private TaskVersionChangeSnapshot findSnapshot(String taskId, Long repoId, Long prNumber) {
        return taskVersionChangeSnapshotMapper.selectOne(new LambdaQueryWrapper<TaskVersionChangeSnapshot>()
                .eq(TaskVersionChangeSnapshot::getTaskId, taskId)
                .eq(TaskVersionChangeSnapshot::getRepoId, repoId)
                .eq(TaskVersionChangeSnapshot::getPrNumber, prNumber)
                .last("LIMIT 1"));
    }

    private String writeSnapshotJson(
            GitRepository repo,
            GitPullRequest pullRequest,
            PullRequestMatch match,
            List<GitCommit> visibleCommits,
            List<GitCommitDiff> visibleFiles) {
        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("capturedAt", java.time.LocalDateTime.now().toString());
        payload.put("matchSource", match.getMatchSource());
        payload.put("repo", Map.of(
                "id", repo.getId(),
                "name", repoLabel(repo),
                "fullName", nullToEmpty(repo.getFullName()),
                "platform", nullToEmpty(repo.getPlatform())));
        payload.put("pullRequest", pullRequest);
        payload.put("commits", visibleCommits);
        payload.put("allCommits", match.getCommits());
        payload.put("matchedCommits", match.getMatchedCommits());
        payload.put("files", visibleFiles);
        try {
            return objectMapper.writeValueAsString(payload);
        } catch (JsonProcessingException ex) {
            throw new IllegalStateException("版本变更快照序列化失败", ex);
        }
    }

    private DiffStats calculateStats(List<GitCommitDiff> files) {
        DiffStats stats = new DiffStats();
        for (GitCommitDiff file : files) {
            stats.addAdditions(resolveLineCount(file.getAdditions(), file.getDiff(), '+'));
            stats.addDeletions(resolveLineCount(file.getDeletions(), file.getDiff(), '-'));
        }
        return stats;
    }

    private int resolveLineCount(Integer value, String diff, char marker) {
        if (value != null && value > 0) {
            return value;
        }
        if (!StringUtils.hasText(diff)) {
            return 0;
        }
        int count = 0;
        for (String line : diff.split("\\n")) {
            if (marker == '+' && line.startsWith("+") && !line.startsWith("+++")) {
                count++;
            } else if (marker == '-' && line.startsWith("-") && !line.startsWith("---")) {
                count++;
            }
        }
        return count;
    }

    private TaskVersionChangeSnapshotDTO toDto(TaskVersionChangeSnapshot snapshot) {
        TaskVersionChangeSnapshotDTO dto = new TaskVersionChangeSnapshotDTO();
        BeanUtils.copyProperties(snapshot, dto);
        return dto;
    }

    private boolean commitMatchesGitIdentity(GitCommit commit, UserGitIdentity identity) {
        String authorEmail = normalize(commit.getAuthorEmail());
        String gitEmail = normalize(identity.getGitEmail());
        if (StringUtils.hasText(authorEmail) && authorEmail.equals(gitEmail)) {
            return true;
        }
        return matchesText(commit.getAuthorName(), identity.getGitUsername())
                || matchesText(commit.getAuthorName(), identity.getGitUserId());
    }

    private boolean pullRequestMatchesGitIdentity(GitPullRequest pullRequest, UserGitIdentity identity) {
        return matchesText(pullRequest.getAuthorName(), identity.getGitUsername())
                || matchesText(pullRequest.getAuthorName(), identity.getGitUserId());
    }

    private boolean matchesText(String source, String expected) {
        String sourceText = normalize(source);
        String expectedText = normalize(expected);
        return StringUtils.hasText(sourceText)
                && StringUtils.hasText(expectedText)
                && (sourceText.equals(expectedText) || sourceText.contains(expectedText));
    }

    private boolean hasGitIdentity(UserGitIdentity identity) {
        return identity != null && (StringUtils.hasText(identity.getGitUsername())
                || StringUtils.hasText(identity.getGitEmail())
                || StringUtils.hasText(identity.getGitUserId()));
    }

    private String repoLabel(GitRepository repo) {
        if (repo == null) {
            return "未知仓库";
        }
        if (StringUtils.hasText(repo.getFullName())) {
            return repo.getFullName();
        }
        if (StringUtils.hasText(repo.getName())) {
            return repo.getName();
        }
        return "仓库 " + repo.getId();
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

    private Long parseLong(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        try {
            return Long.valueOf(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private String normalize(String value) {
        return StringUtils.hasText(value) ? value.trim().toLowerCase(Locale.ROOT) : "";
    }

    @Data
    public static class MergeSummary {
        private int matchedCount;
        private int mergedCount;
        private int alreadyMergedCount;
        private int snapshotCount;
        private final List<String> mergedTargets = new ArrayList<>();
        private final List<String> alreadyMergedTargets = new ArrayList<>();
        private final List<String> skippedReasons = new ArrayList<>();

        private void incrementMatchedCount() {
            matchedCount++;
        }

        private void addMerged(String target) {
            mergedCount++;
            mergedTargets.add(target);
        }

        private void addAlreadyMerged(String target) {
            alreadyMergedCount++;
            alreadyMergedTargets.add(target);
        }

        private void incrementSnapshotCount() {
            snapshotCount++;
        }

        private void addSkipped(String reason) {
            skippedReasons.add(reason);
        }

        public String toLogText() {
            if (snapshotCount > 0) {
                List<String> details = new ArrayList<>();
                if (mergedCount > 0) {
                    details.add("已自动合并 " + mergedCount + " 个 master MR: " + String.join("、", mergedTargets));
                }
                if (alreadyMergedCount > 0) {
                    details.add("已识别已合并 master MR " + alreadyMergedCount + " 个: " + String.join("、", alreadyMergedTargets));
                }
                details.add("已固化版本变更快照 " + snapshotCount + " 个");
                return String.join("；", details);
            }
            return "未自动合并 master MR: " + String.join("、", skippedReasons);
        }
    }

    @Data
    private static class PullRequestMatch {
        private final boolean matched;
        private final String matchSource;
        private final List<GitCommit> commits;
        private final List<GitCommit> matchedCommits;
    }

    @Data
    private static class DiffStats {
        private int additions;
        private int deletions;

        private void addAdditions(int value) {
            additions += value;
        }

        private void addDeletions(int value) {
            deletions += value;
        }
    }
}
