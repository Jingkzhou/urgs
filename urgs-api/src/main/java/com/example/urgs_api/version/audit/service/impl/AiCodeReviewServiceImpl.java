package com.example.urgs_api.version.audit.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.ai.service.AiChatService;
import com.example.urgs_api.version.audit.entity.AiCodeReview;
import com.example.urgs_api.version.audit.mapper.AiCodeReviewMapper;
import com.example.urgs_api.version.audit.service.AiCodeReviewService;
import com.example.urgs_api.version.dto.GitCommit;
import com.example.urgs_api.version.dto.GitCommitDiff;
import com.example.urgs_api.version.service.GitPlatformService;
import com.example.urgs_api.version.service.GitRepositoryService;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.ArrayList;
import java.util.stream.Collectors;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.example.urgs_api.version.audit.service.CodeChunker;
import com.example.urgs_api.version.audit.service.ReviewPromptFactory;

@Service
public class AiCodeReviewServiceImpl extends ServiceImpl<AiCodeReviewMapper, AiCodeReview>
        implements AiCodeReviewService {

    private final GitPlatformService gitPlatformService;
    private final GitRepositoryService gitRepositoryService;
    private final AiChatService aiChatService;

    private final CodeChunker codeChunker;
    private final ReviewPromptFactory reviewPromptFactory;
    private final ObjectMapper objectMapper;

    public AiCodeReviewServiceImpl(GitPlatformService gitPlatformService,
            GitRepositoryService gitRepositoryService,
            AiChatService aiChatService,
            CodeChunker codeChunker,
            ReviewPromptFactory reviewPromptFactory,
            ObjectMapper objectMapper) {
        this.gitPlatformService = gitPlatformService;
        this.gitRepositoryService = gitRepositoryService;
        this.aiChatService = aiChatService;
        this.codeChunker = codeChunker;
        this.reviewPromptFactory = reviewPromptFactory;
        this.objectMapper = objectMapper;
    }

    @Async
    @Override
    public void triggerReview(Long repoId, String commitSha, String branch, String developerEmail) {
        System.out.println("DEBUG: Sending AI Code Review for commit: " + commitSha);

        // 1. Check existing
        AiCodeReview existing = getByCommit(commitSha);
        if (existing != null) {
            System.out.println("DEBUG: Review already exists for " + commitSha + ". Deleting to force re-run.");
            removeById(existing.getId());
        }

        // 2. Create pending record
        AiCodeReview review = new AiCodeReview();
        review.setRepoId(repoId);
        review.setCommitSha(commitSha);
        review.setBranch(branch);
        review.setDeveloperEmail(developerEmail);
        review.setStatus("PENDING");
        review.setCreatedAt(LocalDateTime.now());
        save(review);
        System.out.println("DEBUG: Created PENDING review record id: " + review.getId());

        try {
            gitRepositoryService.findById(repoId).orElseThrow(() -> new RuntimeException("仓库不存在"));

            // 3. Get changed files
            System.out.println("DEBUG: Fetching commit detail...");
            GitCommit commitDetail = gitPlatformService.getCommitDetail(repoId, commitSha);
            List<GitCommitDiff> diffs = commitDetail.getDiffs();
            System.out.println("DEBUG: Commit detail fetched. Diffs count: " + (diffs != null ? diffs.size() : "null"));

            if (diffs == null || diffs.isEmpty()) {
                markAsCompleted(review, 100, "未发现变更或差异。", "没有可供审查的内容。", "{}");
                return;
            }

            // 4. Map-Reduce Analysis
            List<String> fileSummaries = new ArrayList<>();
            List<String> allFileIssuesJson = new ArrayList<>();

            for (GitCommitDiff diff : diffs) {
                // Skip deleted files or binaries
                if ("deleted".equals(diff.getStatus()) || isBinary(diff.getNewPath())) {
                    continue;
                }

                String path = diff.getNewPath();
                System.out.println("DEBUG: Processing file: " + path);

                try {
                    // Fetch FULL content
                    System.out.println("DEBUG: Fetching full content for " + path);
                    String fullContent = gitPlatformService.getFileContent(repoId, commitSha, path).getContent();
                    if (fullContent == null || fullContent.isEmpty()) {
                        // Fallback to diff if full content fails (rare)
                        System.out.println("DEBUG: Full content empty, using diff for " + path);
                        fullContent = diff.getDiff();
                    }

                    // Smart Chunking
                    System.out.println("DEBUG: Chunking content for " + path);
                    List<String> chunks = codeChunker.chunkCode(fullContent, getLanguage(path));
                    System.out.println("DEBUG: Chunks generated: " + chunks.size());

                    List<String> chunkIssues = new ArrayList<>();

                    // Map Phase: Analyze each chunk PARALLEL
                    System.out.println("DEBUG: Map Phase - Analyze chunks in parallel: " + chunks.size());
                    List<java.util.concurrent.CompletableFuture<String>> futures = new ArrayList<>();

                    for (int i = 0; i < chunks.size(); i++) {
                        String chunk = chunks.get(i);
                        String lang = getLanguage(path);
                        futures.add(java.util.concurrent.CompletableFuture.supplyAsync(() -> {
                            String prompt = reviewPromptFactory.getMapPhasePrompt(lang, chunk);
                            return callAiSafe(prompt);
                        }));
                    }

                    // Wait for all
                    java.util.concurrent.CompletableFuture
                            .allOf(futures.toArray(new java.util.concurrent.CompletableFuture[0])).join();

                    chunkIssues = futures.stream()
                            .map(java.util.concurrent.CompletableFuture::join)
                            .map(this::extractJson)
                            .collect(Collectors.toList());

                    // REDUCE Phase (File Level): Aggregate chunk results
                    System.out.println("DEBUG: Reduce Phase for file " + path);
                    String joinedIssues = "[" + String.join(",", chunkIssues) + "]";
                    String fileReducePrompt = reviewPromptFactory.getReducePhasePrompt(getLanguage(path), joinedIssues);
                    String fileAnalysisJson = extractJson(callAiSafe(fileReducePrompt));

                    allFileIssuesJson.add(fileAnalysisJson);
                    fileSummaries.add(String.format("### %s\n%s", path, extractSummary(fileAnalysisJson)));
                } catch (Exception e) {
                    System.err.println("DEBUG: Failed to analyze file: " + path + " - " + e.getMessage());
                    e.printStackTrace();
                }
            }

            // 5. Final Aggregation
            // Simple aggregation for now: Average score, combine issues
            System.out.println("DEBUG: Final aggregation...");
            // Ideally we could do one last AI Reduce pass here if needed.
            int finalScore = calculateAverageScore(allFileIssuesJson);
            String finalSummary = "AI 代码智能审查完成。包含 " + allFileIssuesJson.size() + " 个文件的深度分析。";
            String finalContent = fileSummaries.isEmpty()
                    ? "暂无详细分析内容。"
                    : String.join("\n\n---\n\n", fileSummaries);

            // Construct Client-Friendly JSON Structure
            // Merging all "issues" arrays from files
            String finalJson = mergeJsonResults(allFileIssuesJson, finalScore, finalContent, finalSummary);

            markAsCompleted(review, finalScore, finalSummary, finalContent, finalJson);
            System.out.println("DEBUG: Review completed successfully for " + commitSha);

        } catch (Exception e) {
            System.err.println("DEBUG: Top level error in triggerReview: " + e.getMessage());
            e.printStackTrace();
            review.setStatus("FAILED");
            review.setSummary("Error: " + e.getMessage());
        } finally {
            review.setUpdatedAt(LocalDateTime.now());
            updateById(review);
        }
    }

    private void markAsCompleted(AiCodeReview review, int score, String summary, String content, String jsonContent) {
        review.setStatus("COMPLETED");
        review.setScore(score);
        review.setSummary(summary);
        review.setContent(jsonContent); // We store the JSON structure in 'content' now for frontend parsing
    }

    private String callAiSafe(String prompt) {
        try {
            String response = aiChatService.chat(
                    "You are an automated code review engine. Output STRICT JSON only.",
                    prompt);
            System.out.println("DEBUG: Raw AI Response: " + response);
            return response;
        } catch (Exception e) {
            System.err.println("DEBUG: AI Call Failed: " + e.getMessage());
            return "{ \"issues\": [] }"; // Safe fallback
        }
    }

    private String getLanguage(String path) {
        if (path.endsWith(".java"))
            return "java";
        if (path.endsWith(".py"))
            return "python";
        if (path.endsWith(".sql"))
            return "sql";
        if (path.endsWith(".js") || path.endsWith(".ts"))
            return "javascript";
        return "text";
    }

    private boolean isBinary(String path) {
        if (path == null)
            return false;
        String p = path.toLowerCase();
        return p.endsWith(".png") || p.endsWith(".jpg") || p.endsWith(".zip") || p.endsWith(".jar");
    }

    // Helper to extract clean JSON from potentially markdown-wrapped AI response
    private String extractJson(String response) {
        try {
            if (response.contains("```json")) {
                int start = response.indexOf("```json") + 7;
                int end = response.lastIndexOf("```");
                if (end > start)
                    return response.substring(start, end).trim();
            }
            if (response.contains("```")) {
                int start = response.indexOf("```") + 3;
                int end = response.lastIndexOf("```");
                if (end > start)
                    return response.substring(start, end).trim();
            }
            int start = response.indexOf("{");
            int end = response.lastIndexOf("}");
            if (start >= 0 && end > start) {
                return response.substring(start, end + 1);
            }
        } catch (Exception e) {
        }
        return "{\"issues\":[]}";
    }

    private String extractSummary(String json) {
        try {
            JsonNode node = objectMapper.readTree(json);
            if (node.has("content"))
                return node.get("content").asText();
            if (node.has("summary"))
                return node.get("summary").asText();
        } catch (Exception e) {
        }
        return "Analysis available in details.";
    }

    private int calculateAverageScore(List<String> jsons) {
        if (jsons.isEmpty())
            return 100;
        int total = 0;
        int count = 0;
        for (String json : jsons) {
            try {
                JsonNode node = objectMapper.readTree(json);
                if (node.has("score")) {
                    total += node.get("score").asInt();
                    count++;
                }
            } catch (Exception e) {
            }
        }
        return count == 0 ? 100 : total / count;
    }

    private String mergeJsonResults(List<String> jsons, int overallScore, String overallContent,
            String overallSummary) {
        try {
            com.fasterxml.jackson.databind.node.ObjectNode root = objectMapper.createObjectNode();
            com.fasterxml.jackson.databind.node.ArrayNode combinedIssues = objectMapper.createArrayNode();

            int sec = 0, rel = 0, maint = 0, perf = 0;
            int count = 0;

            for (String json : jsons) {
                if (json == null || json.isBlank())
                    continue;
                try {
                    JsonNode node = objectMapper.readTree(json);
                    JsonNode issuesNode = node.get("issues");
                    if (issuesNode != null && issuesNode.isArray()) {
                        issuesNode.forEach(combinedIssues::add);
                    }
                    JsonNode sb = node.get("scoreBreakdown");
                    if (sb != null && sb.isObject()) {
                        sec += sb.path("security").asInt(80);
                        rel += sb.path("reliability").asInt(80);
                        maint += sb.path("maintainability").asInt(80);
                        perf += sb.path("performance").asInt(80);
                        count++;
                    }
                } catch (Exception e) {
                    // Skip invalid JSON chunks instead of failing the whole response.
                }
            }

            if (count == 0) {
                // If no breakdown found, assume consistent with overall score
                sec = overallScore;
                rel = overallScore;
                maint = overallScore;
                perf = overallScore;
                count = 1;
            }

            root.put("score", overallScore);
            root.put("summary", overallSummary);
            root.put("content", overallContent);
            root.set("issues", combinedIssues);
            com.fasterxml.jackson.databind.node.ObjectNode breakdown = root.putObject("scoreBreakdown");
            breakdown.put("security", sec / count);
            breakdown.put("reliability", rel / count);
            breakdown.put("maintainability", maint / count);
            breakdown.put("performance", perf / count);

            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(root);
        } catch (Exception e) {
            return "{}";
        }
    }

    @Override
    public AiCodeReview getByCommit(String commitSha) {
        return getOne(new LambdaQueryWrapper<AiCodeReview>().eq(AiCodeReview::getCommitSha, commitSha));
    }
}
