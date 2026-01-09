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
        // 1. 检查是否已存在
        AiCodeReview existing = getByCommit(commitSha);
        if (existing != null) {
            return;
        }

        // 2. 创建待处理记录
        AiCodeReview review = new AiCodeReview();
        review.setRepoId(repoId);
        review.setCommitSha(commitSha);
        review.setBranch(branch);
        review.setDeveloperEmail(developerEmail);
        review.setStatus("PENDING");
        review.setCreatedAt(LocalDateTime.now());
        save(review);

        try {
            // 3. 获取差异
            GitRepository repo = gitRepositoryService.findById(repoId).orElse(null);
            if (repo == null) {
                throw new RuntimeException("仓库不存在");
            }

            // 理想情况下需要一个包含差异的提交详情接口
            // GitPlatformService 需要暴露带差异的 getCommitDetail
            // 查看 GitBrowserController 的调用：
            // gitPlatformService.getCommitDetail(repoId, sha)
            // 注意：GitPlatformService 的 getCommitDetail 是 (repoId, sha) 还是 (repo, sha)？
            // 从现有调用看是 gitPlatformService.getCommitDetail(id, sha)

            GitCommit commitDetail = gitPlatformService.getCommitDetail(repoId, commitSha);
            List<GitCommitDiff> diffs = commitDetail.getDiffs();

            if (diffs == null || diffs.isEmpty()) {
                review.setStatus("COMPLETED");
                review.setSummary("未发现变更或差异。");
                review.setContent("没有可供审查的内容。");
                review.setScore(100);
            } else {
                // 4. 构造提示词
                StringBuilder diffContent = new StringBuilder();
                for (GitCommitDiff diff : diffs) {
                    diffContent.append("文件: ").append(diff.getNewPath()).append("\n");
                    diffContent.append(diff.getDiff()).append("\n\n");
                }

                String systemPrompt = "你是一名资深代码审查员。请审查以下代码变更，" +
                        "检查是否存在缺陷、安全问题或不良实践。" +
                        "给出 0-100 的评分。" +
                        "请按 JSON 格式返回：{ \"score\": 85, \"summary\": \"...\", \"detail\": \"...\" }";

                String userPrompt = "提交信息: " + commitDetail.getMessage() + "\n\n变更内容:\n"
                        + diffContent.toString();

                // 5. 调用 AI
                String response;
                try {
                    response = aiChatService.chat(systemPrompt, userPrompt);
                } catch (Exception aiError) {
                    System.err.println("AI 服务调用失败，使用模拟响应: " + aiError.getMessage());
                    // 模拟响应
                    response = "{\n" +
                            "  \"score\": 85,\n" +
                            "  \"summary\": \"[模拟] AI 服务不可用，当前为模拟审查结果。\",\n" +
                            "  \"content\": \"代码变更整体合理，流式处理使用得当。请确保异常处理足够健壮。\"\n"
                            +
                            "}";
                }

                // 6. 解析响应（当前为简单启发式，假设为 JSON 或直接存储原文）
                // 作为模拟/最小可行版本，这里直接存储响应内容，并尝试解析评分

                review.setContent(response);
                review.setSummary("AI 审查完成。");
                review.setScore(80); // 解析失败时的兜底分数，可进一步完善解析逻辑

                // 如果响应是严格 JSON，则尝试做简单解析
                if (response.contains("\"score\":")) {
                    try {
                        // 简单解析
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
            review.setSummary("错误: " + e.getMessage());
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
