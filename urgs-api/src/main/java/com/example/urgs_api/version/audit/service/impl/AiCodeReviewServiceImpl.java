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
        // Create a more lenient mapper for AI responses
        this.objectMapper = objectMapper.copy()
                .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_UNQUOTED_CONTROL_CHARS, true)
                .configure(com.fasterxml.jackson.core.JsonParser.Feature.ALLOW_BACKSLASH_ESCAPING_ANY_CHARACTER, true);
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
            List<FileReviewResult> fileResults = new ArrayList<>();

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

                    String fileSummary = extractSummary(fileAnalysisJson);
                    fileResults.add(new FileReviewResult(path, getLanguage(path), fileSummary, fileAnalysisJson));
                } catch (Exception e) {
                    System.err.println("DEBUG: Failed to analyze file: " + path + " - " + e.getMessage());
                    e.printStackTrace();
                }
            }

            // 5. Final Aggregation
            // Simple aggregation for now: Average score, combine issues
            System.out.println("DEBUG: Final aggregation...");
            // Ideally we could do one last AI Reduce pass here if needed.
            List<String> allFileIssuesJson = fileResults.stream()
                    .map(FileReviewResult::json)
                    .collect(Collectors.toList());
            int finalScore = calculateAverageScore(allFileIssuesJson);
            String finalSummary = "AI 代码智能审查完成。包含 " + fileResults.size() + " 个文件的深度分析。";
            String finalContent = fileResults.isEmpty()
                    ? "暂无详细分析内容。"
                    : fileResults.stream()
                            .map(file -> String.format("### %s\n%s", file.path(), file.summary()))
                            .collect(Collectors.joining("\n\n---\n\n"));

            // Construct Client-Friendly JSON Structure
            // Merging all "issues" arrays from files
            String finalJson = mergeJsonResults(fileResults, finalScore, finalContent, finalSummary);

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

    private boolean isBinary(String path) {
        if (path == null)
            return false;
        String p = path.toLowerCase();
        return p.endsWith(".png") || p.endsWith(".jpg") || p.endsWith(".zip") || p.endsWith(".jar");
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
                System.out.println("DEBUG: calculateAverageScore parsing: " + truncate(json, 100));
                JsonNode node = objectMapper.readTree(json);
                if (node.has("score")) {
                    int s = node.get("score").asInt();
                    System.out.println("DEBUG: Found score: " + s);
                    total += s;
                    count++;
                } else {
                    System.out.println("DEBUG: No score field found in JSON");
                }
            } catch (Exception e) {
                System.err.println("DEBUG: calculateAverageScore parse failed: " + e.getMessage());
            }
        }
        int avg = (count == 0) ? 100 : total / count;
        System.out.println("DEBUG: Average Score calculated: " + avg);
        return avg;
    }

    private String truncate(String s, int len) {
        if (s == null || s.length() <= len)
            return s;
        return s.substring(0, len) + "...";
    }

    private String mergeJsonResults(List<FileReviewResult> fileResults, int overallScore, String overallContent,
            String overallSummary) {
        try {
            com.fasterxml.jackson.databind.node.ObjectNode root = objectMapper.createObjectNode();
            com.fasterxml.jackson.databind.node.ArrayNode combinedIssues = objectMapper.createArrayNode();
            com.fasterxml.jackson.databind.node.ArrayNode files = objectMapper.createArrayNode();

            int sec = 0, rel = 0, maint = 0, perf = 0;
            int count = 0;

            for (FileReviewResult fileResult : fileResults) {
                String json = fileResult.json();
                if (json == null || json.isBlank())
                    continue;
                try {
                    JsonNode node = objectMapper.readTree(json);
                    com.fasterxml.jackson.databind.node.ObjectNode fileNode = files.addObject();
                    fileNode.put("path", fileResult.path());
                    fileNode.put("fileName", getFileName(fileResult.path()));
                    fileNode.put("language", fileResult.language());
                    fileNode.put("summary", fileResult.summary());
                    if (node.has("score")) {
                        fileNode.put("score", node.get("score").asInt());
                    }

                    int issueCount = 0;
                    JsonNode issuesNode = node.get("issues");
                    if (issuesNode != null && issuesNode.isArray()) {
                        for (JsonNode issue : issuesNode) {
                            issueCount++;
                            if (issue != null && issue.isObject()) {
                                com.fasterxml.jackson.databind.node.ObjectNode enrichedIssue = issue.deepCopy();
                                enrichedIssue.put("filePath", fileResult.path());
                                enrichedIssue.put("fileName", getFileName(fileResult.path()));
                                enrichedIssue.put("language", fileResult.language());
                                combinedIssues.add(enrichedIssue);
                            } else {
                                combinedIssues.add(issue);
                            }
                        }
                    }
                    fileNode.put("issueCount", issueCount);

                    JsonNode sb = node.get("scoreBreakdown");
                    if (sb != null && sb.isObject()) {
                        sec += sb.path("security").asInt(80);
                        rel += sb.path("reliability").asInt(80);
                        maint += sb.path("maintainability").asInt(80);
                        perf += sb.path("performance").asInt(80);
                        count++;
                    }
                } catch (Exception e) {
                    System.err.println("DEBUG: mergeJsonResults parse failed for chunk: " + e.getMessage());
                }
            }

            if (count == 0) {
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
            root.set("files", files);
            com.fasterxml.jackson.databind.node.ObjectNode breakdown = root.putObject("scoreBreakdown");
            breakdown.put("security", sec / count);
            breakdown.put("reliability", rel / count);
            breakdown.put("maintainability", maint / count);
            breakdown.put("performance", perf / count);

            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(root);
        } catch (Exception e) {
            System.err.println("DEBUG: mergeJsonResults top level failed: " + e.getMessage());
            return "{}";
        }
    }

    @Override
    public AiCodeReview getByCommit(String commitSha) {
        return getOne(new LambdaQueryWrapper<AiCodeReview>().eq(AiCodeReview::getCommitSha, commitSha));
    }

    @Override
    public String askReview(Long reviewId, String question, String issueTitle, String issueSeverity) {
        if (question == null || question.isBlank()) {
            throw new IllegalArgumentException("问题不能为空");
        }

        AiCodeReview review = getById(reviewId);
        if (review == null) {
            throw new IllegalArgumentException("智查报告不存在");
        }
        if (!"COMPLETED".equals(review.getStatus())) {
            throw new IllegalStateException("智查报告尚未完成，暂不能追问");
        }

        String systemPrompt = """
                你是一个资深代码审查报告分析助手。
                你只能基于已完成的智查报告内容回答，不要编造报告中不存在的文件、行号或结论。
                输出使用中文 Markdown，结构必须简洁：先给结论，再给依据，最后给下一步建议。
                如果证据不足，请明确说明需要补充哪些上下文。
                """;

        String userPrompt = String.format(
                """
                        智查报告元数据：
                        - reviewId: %s
                        - repoId: %s
                        - commitSha: %s
                        - branch: %s
                        - score: %s
                        - summary: %s
                        - issueTitle: %s
                        - issueSeverity: %s

                        智查报告内容（JSON 或 Markdown）：
                        %s

                        用户追问：
                        %s
                        """,
                review.getId(),
                review.getRepoId(),
                safeText(review.getCommitSha(), 200),
                safeText(review.getBranch(), 200),
                review.getScore(),
                safeText(review.getSummary(), 1000),
                safeText(issueTitle, 300),
                safeText(issueSeverity, 80),
                safeText(review.getContent(), 12000),
                safeText(question, 1200));

        return aiChatService.chat(systemPrompt, userPrompt);
    }

    private String getLanguage(String path) {
        if (path == null)
            return "text";
        String p = path.toLowerCase();
        if (p.endsWith(".java"))
            return "java";
        if (p.endsWith(".py"))
            return "python";
        if (p.endsWith(".sql") || p.endsWith(".prc") || p.endsWith(".pck") || p.endsWith(".fnc") || p.endsWith(".trg"))
            return "sql";
        if (p.endsWith(".js") || p.endsWith(".ts") || p.endsWith(".jsx") || p.endsWith(".tsx"))
            return "javascript";
        if (p.endsWith(".vue"))
            return "javascript";
        if (p.endsWith(".xml") || p.endsWith(".html"))
            return "xml";
        return "text";
    }

    private String extractJson(String response) {
        if (response == null || response.isBlank())
            return "{\"issues\":[]}";
        try {
            String clean = response.trim();
            if (clean.contains("```")) {
                int start = clean.indexOf("```");
                if (clean.substring(start).startsWith("```json")) {
                    start += 7;
                } else {
                    start += 3;
                }
                int end = clean.lastIndexOf("```");
                if (end > start) {
                    clean = clean.substring(start, end).trim();
                }
            }
            int firstBrace = clean.indexOf("{");
            int lastBrace = clean.lastIndexOf("}");
            if (firstBrace >= 0 && lastBrace > firstBrace) {
                return sanitizeJson(clean.substring(firstBrace, lastBrace + 1));
            }
            return sanitizeJson(clean);
        } catch (Exception e) {
            return "{\"issues\":[]}";
        }
    }

    private String sanitizeJson(String json) {
        if (json == null)
            return "{}";
        // Remove trailing commas before } or ]
        String sanitized = json.replaceAll(",\\s*([}\\]])", "$1");
        // AI sometimes produces unescaped quotes inside strings. Very hard to fix
        // perfectly without a real parser,
        // but let's hope Jackson's lenient mode handles most.
        return sanitized;
    }

    private String safeText(String text, int maxLength) {
        if (text == null || text.isBlank()) {
            return "-";
        }
        String normalized = text.trim();
        if (normalized.length() <= maxLength) {
            return normalized;
        }
        return normalized.substring(0, maxLength) + "...";
    }

    private String getFileName(String path) {
        if (path == null || path.isBlank()) {
            return "-";
        }
        int slashIndex = Math.max(path.lastIndexOf('/'), path.lastIndexOf('\\'));
        if (slashIndex >= 0 && slashIndex < path.length() - 1) {
            return path.substring(slashIndex + 1);
        }
        return path;
    }

    private record FileReviewResult(String path, String language, String summary, String json) {
    }
}
