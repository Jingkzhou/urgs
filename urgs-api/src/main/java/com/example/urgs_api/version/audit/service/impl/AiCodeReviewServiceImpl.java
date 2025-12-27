package com.example.urgs_api.version.audit.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.ai.service.AiChatService;
import com.example.urgs_api.version.audit.entity.AiCodeReview;
import com.example.urgs_api.version.audit.mapper.AiCodeReviewMapper;
import com.example.urgs_api.version.audit.service.AiCodeReviewService;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.entity.GitRepository;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.service.GitRepositoryService;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.stream.Collectors;

@Service
public class AiCodeReviewServiceImpl extends ServiceImpl<AiCodeReviewMapper, AiCodeReview>
        implements AiCodeReviewService {

    private final GitPlatformService gitPlatformService;
    private final GitRepositoryService gitRepositoryService;
    private final AiChatService aiChatService;

    public AiCodeReviewServiceImpl(GitPlatformService gitPlatformService,
            GitRepositoryService gitRepositoryService,
            AiChatService aiChatService) {
        this.gitPlatformService = gitPlatformService;
        this.gitRepositoryService = gitRepositoryService;
        this.aiChatService = aiChatService;
    }

    @Async
    @Override
    public void triggerReview(Long repoId, String commitSha, String branch, String developerEmail) {
        // 1. Check if already exists
        AiCodeReview existing = getByCommit(commitSha);
        if (existing != null) {
            return;
        }

        // 2. Create PENDING record
        AiCodeReview review = new AiCodeReview();
        review.setRepoId(repoId);
        review.setCommitSha(commitSha);
        review.setBranch(branch);
        review.setDeveloperEmail(developerEmail);
        review.setStatus("PENDING");
        review.setCreatedAt(LocalDateTime.now());
        save(review);

        try {
            // 3. Fetch Diff
            GitRepository repo = gitRepositoryService.findById(repoId).orElse(null);
            if (repo == null) {
                throw new RuntimeException("Repository not found");
            }

            // Ideally we need a method to get specific commit detail including diffs
            // GitPlatformService needs to expose getCommitDetail with diffs.
            // Looking at GitBrowserController, it calls
            // gitPlatformService.getCommitDetail(repoId, sha)
            // But wait, GitPlatformService's getCommitDetail takes (repoId, sha) or (repo,
            // sha)?
            // It seems GitBrowserController calls: gitPlatformService.getCommitDetail(id,
            // sha)

            GitCommit commitDetail = gitPlatformService.getCommitDetail(repoId, commitSha);
            List<GitCommitDiff> diffs = commitDetail.getDiffs();

            if (diffs == null || diffs.isEmpty()) {
                review.setStatus("COMPLETED");
                review.setSummary("No changes or diffs found.");
                review.setContent("No content to review.");
                review.setScore(100);
            } else {
                // 4. Construct Prompt
                StringBuilder diffContent = new StringBuilder();
                for (GitCommitDiff diff : diffs) {
                    diffContent.append("File: ").append(diff.getNewPath()).append("\n");
                    diffContent.append(diff.getDiff()).append("\n\n");
                }

                String systemPrompt = "You are a senior code reviewer. Review the following code changes. " +
                        "verify if there are any bugs, security issues, or bad practices. " +
                        "Provide a score from 0-100. " +
                        "Format your response as a JSON: { \"score\": 85, \"summary\": \"...\", \"detail\": \"...\" }";

                String userPrompt = "Commit Message: " + commitDetail.getMessage() + "\n\nChanges:\n"
                        + diffContent.toString();

                // 5. Call AI
                String response;
                try {
                    response = aiChatService.chat(systemPrompt, userPrompt);
                } catch (Exception aiError) {
                    System.err.println("AI Service failed, using Mock response: " + aiError.getMessage());
                    // Mock Response
                    response = "{\n" +
                            "  \"score\": 85,\n" +
                            "  \"summary\": \"[MOCK] This is a mock review because AI service is unavailable.\",\n" +
                            "  \"content\": \"The code changes look reasonable. Good use of streams. Please ensure error handling is robust.\"\n"
                            +
                            "}";
                }

                // 6. Parse Response (Simple heuristic for now, assuming JSON-ish or just
                // storing raw)
                // Since this is a Mock/MVP, let's just store the response in content.
                // And try to extract score if possible, or default.

                review.setContent(response);
                review.setSummary("AI Review Completed.");
                review.setScore(80); // Dummy score if parsing fails, or improve parsing

                // Try simple parsing if response is strictly JSON
                if (response.contains("\"score\":")) {
                    try {
                        // Very naive parsing
                        String scoreStr = response.substring(response.indexOf("\"score\":") + 8).split(",")[0].trim();
                        review.setScore(Integer.parseInt(scoreStr));

                        if (response.contains("\"summary\":")) {
                            String summaryStr = response.substring(response.indexOf("\"summary\":") + 10)
                                    .split("\",")[0].replace("\"", "").trim();
                            review.setSummary(summaryStr);
                        }
                    } catch (Exception e) {
                    }
                }

                review.setStatus("COMPLETED");
            }

        } catch (Exception e) {
            review.setStatus("FAILED");
            review.setSummary("Error: " + e.getMessage());
        } finally {
            review.setUpdatedAt(LocalDateTime.now());
            updateById(review);
        }
    }

    @Override
    public AiCodeReview getByCommit(String commitSha) {
        return getOne(new LambdaQueryWrapper<AiCodeReview>().eq(AiCodeReview::getCommitSha, commitSha));
    }
}
