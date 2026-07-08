package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.user.mapper.UserGitIdentityMapper;
import com.example.urgs_api.user.model.UserGitIdentity;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitPullRequest;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.service.GitRepositoryService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
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

    public MergeSummary mergeOpenMasterPullRequests(Work work, WorkTask task) {
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
            mergeRepositoryPullRequests(repo, tokens, identity, summary);
        }

        if (summary.getMatchedCount() == 0) {
            summary.addSkipped("未找到目标分支为 master 的待合并 MR");
        }
        return summary;
    }

    private void mergeRepositoryPullRequests(
            GitRepository repo,
            List<String> tokens,
            UserGitIdentity identity,
            MergeSummary summary) {
        List<GitPullRequest> pullRequests;
        try {
            pullRequests = gitPlatformService.getPullRequests(repo.getId(), "open", 1, 100);
        } catch (RuntimeException ex) {
            log.warn("任务中心自动合并读取 MR 失败: repoId={}", repo.getId(), ex);
            summary.addSkipped(repoLabel(repo) + " 读取 MR 失败");
            return;
        }

        for (GitPullRequest pullRequest : pullRequests) {
            if (!isRequirementMatched(pullRequest, tokens) || !isMasterTarget(pullRequest)) {
                continue;
            }
            if (!isIdentityMatched(repo, pullRequest, identity)) {
                continue;
            }

            summary.incrementMatchedCount();
            try {
                gitPlatformService.mergePullRequest(repo.getId(), pullRequest.getNumber(), "merge");
                summary.addMerged(repoLabel(repo) + " !" + pullRequest.getNumber());
            } catch (RuntimeException ex) {
                throw new IllegalStateException(
                        "自动合并到 master 失败: " + repoLabel(repo) + " !" + pullRequest.getNumber() + " - " + ex.getMessage(),
                        ex);
            }
        }
    }

    private boolean isIdentityMatched(GitRepository repo, GitPullRequest pullRequest, UserGitIdentity identity) {
        List<GitCommit> commits = gitPlatformService.getPullRequestCommits(repo.getId(), pullRequest.getNumber());
        boolean commitMatched = commits.stream().anyMatch(commit -> commitMatchesGitIdentity(commit, identity));
        return commitMatched || pullRequestMatchesGitIdentity(pullRequest, identity);
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
        private final List<String> mergedTargets = new ArrayList<>();
        private final List<String> skippedReasons = new ArrayList<>();

        private void incrementMatchedCount() {
            matchedCount++;
        }

        private void addMerged(String target) {
            mergedCount++;
            mergedTargets.add(target);
        }

        private void addSkipped(String reason) {
            skippedReasons.add(reason);
        }

        public String toLogText() {
            if (mergedCount > 0) {
                return "已自动合并 " + mergedCount + " 个 master MR: " + String.join("、", mergedTargets);
            }
            return "未自动合并 master MR: " + String.join("、", skippedReasons);
        }
    }
}
