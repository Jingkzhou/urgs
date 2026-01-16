package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Consumer;

/**
 * AI 聊天服务实现
 * 使用 OpenAI 兼容 API 格式，支持多种 AI 服务商
 */
@Service
public class AiChatServiceImpl implements AiChatService {

    private static final Logger log = LoggerFactory.getLogger(AiChatServiceImpl.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();

    @Autowired
    private AiApiConfigService aiApiConfigService;

    @Autowired
    private AiUsageLogService aiUsageLogService;

    @Autowired
    private AiChatHistoryService aiChatHistoryService; // Inject history service

    @Autowired
    private com.example.urgs_api.ai.repository.AgentRepository agentRepository;

    @Autowired
    private com.example.urgs_api.ai.repository.KnowledgeBaseRepository knowledgeBaseRepository;

    @Autowired
    private RagService ragService;

    @Override
    public String chat(String systemPrompt, String userPrompt) {
        return chat(systemPrompt, userPrompt, "chat");
    }

    /**
     * 同步聊天（带请求类型）
     */
    public String chat(String systemPrompt, String userPrompt, String requestType) {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt));
        StringBuilder result = new StringBuilder();
        executeCoreStream(messages, requestType, result::append, () -> {
        }, e -> {
            log.error("AI chat error", e);
            throw new RuntimeException("AI 响应失败: " + e.getMessage());
        });
        return result.toString();
    }

    public void streamChat(String systemPrompt, String userPrompt, SseEmitter emitter) {
        streamChat(systemPrompt, userPrompt, "chat", emitter);
    }

    public void streamChat(String systemPrompt, String userPrompt, String requestType, SseEmitter emitter) {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt));
        streamChat(messages, requestType, emitter);
    }

    /**
     * 持久化流式聊天 (New)
     */
    // Configuration Constants
    private static final int MAX_CONTEXT_TOKENS = 30000; // 上下文最大 Token 限制
    private static final double TRIGGER_THRESHOLD = 0.2; // 触发压缩的阈值比例 (0.2 means 20% of MAX_TOKENS triggers compression
                                                         // - Modified for testing)
    private static final int KEEP_RECENT_ROUNDS = 3; // 保留最近的对话轮数 (不被压缩)

    /**
     * 持久化流式聊天 (New)
     * 核心流程：保存用户消息 -> 检查是否触发压缩 -> 获取历史并构建上下文 -> 发送 Metrics -> 流式响应 -> 保存 AI 消息
     */
    public void streamChatWithPersistence(String sessionId, String systemPrompt, String userPrompt,
            SseEmitter emitter) {
        log.info("Starting streamChatWithPersistence for session: {}", sessionId);

        // 1. 保存用户消息 (Save User Message)
        aiChatHistoryService.saveMessage(sessionId, "user", userPrompt);

        // ==========================================
        // Multi-Agent & RAG Logic
        // ==========================================
        String contextAugmentation = "";
        try {
            com.example.urgs_api.ai.entity.AiChatSession sessionInfo = aiChatHistoryService.getSession(sessionId);
            if (sessionInfo != null && sessionInfo.getAgentId() != null) {
                com.example.urgs_api.ai.entity.Agent agent = agentRepository.selectById(sessionInfo.getAgentId());
                if (agent != null) {

                    log.info("Checking Agent Configuration - ID: {}, Name: {}, KB: {}",
                            agent.getId(), agent.getName(), agent.getKnowledgeBase());

                    // 1. Agent System Prompt Override
                    if (agent.getSystemPrompt() != null && !agent.getSystemPrompt().isBlank()) {
                        systemPrompt = agent.getSystemPrompt();
                    }

                    // 2. RAG Retrieval
                    if (agent.getKnowledgeBase() != null && !agent.getKnowledgeBase().isBlank()) {
                        java.util.List<String> collectionNames = new java.util.ArrayList<>();
                        String[] kbIds = agent.getKnowledgeBase().split(",");
                        for (String kbIdStr : kbIds) {
                            String target = kbIdStr.trim();
                            if (target.isEmpty())
                                continue;

                            com.example.urgs_api.ai.entity.KnowledgeBase kb = null;
                            try {
                                if (target.matches("\\d+")) { // Check if it's a number
                                    Long kbId = Long.parseLong(target);
                                    kb = knowledgeBaseRepository.selectById(kbId);
                                }
                            } catch (Exception e) {
                                log.warn("Failed to parse KB ID: {}", target);
                            }

                            if (kb == null) {
                                // Try lookup by name or collection name
                                try {
                                    kb = knowledgeBaseRepository.selectOne(
                                            new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.example.urgs_api.ai.entity.KnowledgeBase>()
                                                    .eq(com.example.urgs_api.ai.entity.KnowledgeBase::getName, target)
                                                    .or()
                                                    .eq(com.example.urgs_api.ai.entity.KnowledgeBase::getCollectionName,
                                                            target));
                                } catch (Exception e) {
                                    log.warn("KB lookup by name/collection failed for: {}", target);
                                }
                            }

                            if (kb != null) {
                                log.info("Found KnowledgeBase - ID: {}, Collection: {}", kb.getId(),
                                        kb.getCollectionName());
                                if (kb.getCollectionName() != null) {
                                    collectionNames.add(kb.getCollectionName());
                                }
                            } else {
                                log.warn("KnowledgeBase not found for target: {}", target);
                            }
                        }

                        if (!collectionNames.isEmpty()) {
                            log.info("Performing RAG Query for Agent {} on Collections: {}", agent.getName(),
                                    collectionNames);

                            // Send status update to frontend
                            try {
                                emitter.send(SseEmitter.event().name("status").data("searching"));
                            } catch (Exception e) {
                                log.warn("Failed to send searching status", e);
                            }

                            com.example.urgs_api.ai.dto.RagQueryRequest ragReq = new com.example.urgs_api.ai.dto.RagQueryRequest();
                            ragReq.setQuery(userPrompt);
                            ragReq.setCollectionNames(collectionNames);
                            ragReq.setK(4);

                            try {
                                com.example.urgs_api.ai.dto.RagQueryResponse ragRes = ragService.query(ragReq);

                                // [New] Send Intent
                                if (ragRes != null && ragRes.getIntent() != null) {
                                    try {
                                        // Send as JSON object to be easily parsed by frontend (which ignores event
                                        // names mostly)
                                        String intentJson = objectMapper
                                                .writeValueAsString(Map.of("intent", ragRes.getIntent()));
                                        emitter.send(SseEmitter.event().data(intentJson));
                                        log.info("Sent intent: {}", ragRes.getIntent());
                                    } catch (Exception e) {
                                        log.warn("Failed to send intent SSE", e);
                                    }
                                }

                                if (ragRes != null && ragRes.getEffectiveResults() != null
                                        && !ragRes.getEffectiveResults().isEmpty()) {
                                    StringBuilder sourcesBuilder = new StringBuilder();
                                    List<Map<String, Object>> sourceList = new java.util.ArrayList<>();

                                    // ===== [RELEVANCE THRESHOLD] Filter low-score results =====
                                    // RRF scores typically range 0~0.1, so threshold must be low
                                    final double SCORE_THRESHOLD = 0.02; // Minimum relevance score for RRF
                                    List<Map<String, Object>> filteredResults = ragRes.getEffectiveResults().stream()
                                            .filter(r -> {
                                                Object scoreObj = r.get("score");
                                                if (scoreObj instanceof Number) {
                                                    return ((Number) scoreObj).doubleValue() >= SCORE_THRESHOLD;
                                                }
                                                return false; // Discard if no score
                                            })
                                            .collect(java.util.stream.Collectors.toList());

                                    log.info("RAG Results: {} total, {} after threshold filter (>= {})",
                                            ragRes.getEffectiveResults().size(), filteredResults.size(),
                                            SCORE_THRESHOLD);

                                    // ===== [DOCUMENT GROUPING] Group by source file =====
                                    Map<String, List<Map<String, Object>>> groupedByFile = new java.util.LinkedHashMap<>();
                                    Map<String, Double> fileMaxScore = new java.util.HashMap<>();

                                    for (Map<String, Object> res : filteredResults) {
                                        Object metadata = res.get("metadata");
                                        String fileName = "Unknown";
                                        if (metadata instanceof Map) {
                                            @SuppressWarnings("unchecked")
                                            Map<String, Object> metaMap = (Map<String, Object>) metadata;
                                            Object fileNameObj = metaMap.get("file_name");
                                            fileName = fileNameObj != null ? String.valueOf(fileNameObj) : "Unknown";
                                        }

                                        groupedByFile.computeIfAbsent(fileName, k -> new java.util.ArrayList<>())
                                                .add(res);

                                        // Track max score per file
                                        Object scoreObj = res.get("score");
                                        double score = (scoreObj instanceof Number) ? ((Number) scoreObj).doubleValue()
                                                : 0;
                                        fileMaxScore.merge(fileName, score, Math::max);
                                    }

                                    // Sort files by max score (highest first)
                                    List<String> sortedFiles = groupedByFile.keySet().stream()
                                            .sorted((a, b) -> Double.compare(fileMaxScore.getOrDefault(b, 0.0),
                                                    fileMaxScore.getOrDefault(a, 0.0)))
                                            .collect(java.util.stream.Collectors.toList());

                                    log.info("RAG grouped into {} documents, top: {}", sortedFiles.size(),
                                            sortedFiles.isEmpty() ? "none" : sortedFiles.get(0));

                                    // ===== [FORMAT WITH SOURCE ATTRIBUTION] =====
                                    sourcesBuilder.setLength(0); // Clear and reuse

                                    int docIndex = 1;
                                    for (String fileName : sortedFiles) {
                                        List<Map<String, Object>> chunks = groupedByFile.get(fileName);
                                        double maxScore = fileMaxScore.getOrDefault(fileName, 0.0);

                                        sourcesBuilder.append(String.format("\n【参考资料 %d - 来源: %s (相关度: %.0f%%)】\n",
                                                docIndex++, fileName, maxScore * 100));

                                        for (Map<String, Object> res : chunks) {
                                            Object content = res.get("content");
                                            if (content != null) {
                                                sourcesBuilder.append(content.toString()).append("\n");

                                                // Prepare structured source for frontend
                                                Object metadata = res.get("metadata");
                                                if (metadata instanceof Map) {
                                                    @SuppressWarnings("unchecked")
                                                    Map<String, Object> metaMap = (Map<String, Object>) metadata;
                                                    sourceList.add(Map.of(
                                                            "fileName", metaMap.getOrDefault("file_name", "Unknown"),
                                                            "content", content.toString(),
                                                            "score", res.getOrDefault("score", 0)));
                                                }
                                            }
                                        }
                                    }

                                    if (sourcesBuilder.length() > 0) {
                                        contextAugmentation = "\n\n【参考知识库 / Reference Context】\n" +
                                                "(注：资料按相关度从高到低排列，请优先参考排名靠前的来源)\n" +
                                                sourcesBuilder.toString();
                                    }

                                    // Send sources via SSE
                                    try {
                                        emitter.send(SseEmitter.event().name("sources")
                                                .data(objectMapper.writeValueAsString(sourceList)));
                                    } catch (Exception e) {
                                        log.warn("Failed to send sources SSE", e);
                                    }
                                } else {
                                    // Send empty sources to indicate RAG was attempted but found nothing
                                    try {
                                        emitter.send(SseEmitter.event().name("sources").data("[]"));
                                        log.info("RAG yielded no results for agent {}", agent.getName());
                                    } catch (Exception e) {
                                        log.warn("Failed to send empty sources SSE", e);
                                    }
                                }
                            } catch (Exception e) {
                                log.error("RAG Query Failed", e);
                            }
                        } else {
                            log.warn("Agent has KB configured but no valid collections found.");
                        }
                    }
                }
            }
        } catch (Exception e) {
            log.error("Agent enhancement failed", e);
        }

        // Merge Context to User Prompt logic moved to AFTER message construction to
        // ensure visibility
        // previously: userPrompt = userPrompt + contextAugmentation; (removed as it was
        // ignored)

        // 2. 检查并执行上下文压缩 (Check and Summarize if needed)
        // 如果当前 Token 超过阈值，会触发 AI 总结旧消息，并更新 DB 中的 summary 字段
        boolean isSummarized = false;
        try {
            isSummarized = checkAndSummarizeContext(sessionId, emitter);
        } catch (Exception e) {
            log.error("Context summarization failed", e);
            // 失败不影响主流程，继续执行
        }

        // 3. 获取完整历史消息 & 构建最终发送给 AI 的上下文 (Fetch History & Build Context)
        List<com.example.urgs_api.ai.entity.AiChatMessage> history = aiChatHistoryService.getSessionMessages(sessionId);
        com.example.urgs_api.ai.entity.AiChatSession session = aiChatHistoryService.getSession(sessionId);
        String sessionSummary = session != null ? session.getSummary() : null;

        // 构建消息列表：System + [Summary] + Recent History (Pruned)
        List<Map<String, String>> messages = buildContextMessages(systemPrompt, history, sessionSummary);

        // [RAG ENHANCEMENT]: Inject Context & Strict Instructions directly into the
        // messages list
        if (!contextAugmentation.isEmpty() && !messages.isEmpty()) {
            log.info("Injecting RAG Context into Request Messages");

            // 1. Inject Strict System Requirements
            Map<String, String> sysMsg = messages.get(0);
            if ("system".equals(sysMsg.get("role"))) {
                // Default Instructions (Strengthened to prevent cross-document pollution)
                String ragInstructions = """
                        [RAG Mode Active]
                        You are a knowledge-grounded AI assistant. Follow these rules STRICTLY:

                        [CORE RULES]
                        1. You MUST answer ONLY based on the provided Reference Context below.
                        2. If the context does NOT contain relevant information, reply: "抱歉，知识库中未找到相关信息。"
                        3. Do NOT use any knowledge outside of the provided context. No guessing or fabricating.
                        4. If the context is UNRELATED to the user's question, reply: "检索到的内容与您的问题不相关，暂时无法回答。"

                        [MULTI-SOURCE HANDLING - CRITICAL]
                        5. Reference materials are sorted by relevance (highest first). PRIORITIZE the top-ranked source.
                        6. Do NOT mix or combine information from multiple unrelated documents.
                        7. If different sources discuss different topics, use ONLY the one most relevant to the question.
                        8. When citing, always mention which source (参考资料 1, 参考资料 2, etc.) you are referencing.

                        [ANSWER GUIDELINES]
                        - Quote or summarize accurately from the source.
                        - Keep answers professional and concise.
                        - When context contradicts your internal knowledge, prioritize the context.

                        [End of Instructions]

                        """;

                // Override with Agent-specific configuration if available
                com.example.urgs_api.ai.entity.Agent activeAgent = null;
                try {
                    com.example.urgs_api.ai.entity.AiChatSession sessionInfo = aiChatHistoryService
                            .getSession(sessionId);
                    if (sessionInfo != null && sessionInfo.getAgentId() != null) {
                        activeAgent = agentRepository.selectById(sessionInfo.getAgentId());
                    }
                } catch (Exception e) {
                }

                if (activeAgent != null && activeAgent.getRagInstruction() != null
                        && !activeAgent.getRagInstruction().isBlank()) {
                    log.info("Applying Custom RAG Instructions for Agent: {}", activeAgent.getName());
                    ragInstructions = activeAgent.getRagInstruction() + "\n\n";
                }

                // Modifying the map in place (if mutable) or replacing
                // List.of returns immutable maps, so we must replace the element with a fresh
                // map
                messages.set(0, Map.of("role", "system", "content", ragInstructions + sysMsg.get("content")));
            }

            // 2. Inject Context into the User Message (Last Message)
            int lastIdx = messages.size() - 1;
            Map<String, String> lastMsg = messages.get(lastIdx);
            if ("user".equals(lastMsg.get("role"))) {
                String originalContent = lastMsg.get("content");
                String newContent = String.format("""
                        【用户问题 / User Question】:
                        %s

                        %s
                        """, originalContent, contextAugmentation);
                messages.set(lastIdx, Map.of("role", "user", "content", newContent));
            }
        }

        // 计算当前上下文 Token 用量，用于前端展示 (Calculate usage for frontend display)
        long totalChars = 0;
        for (Map<String, String> msg : messages) {
            totalChars += msg.getOrDefault("content", "").length();
        }
        final long used = totalChars / 4; // 简单估算：4个字符约等于1个 Token
        final long limit = MAX_CONTEXT_TOKENS;

        // 4. 发送 Token 用量数据 & 开启流式响应 (Send Metrics & Stream Response)
        try {
            emitter.send(SseEmitter.event().name("metrics")
                    .data(objectMapper.writeValueAsString(Map.of("used", used, "limit", limit))));
        } catch (Exception e) {
            log.error("Failed to send metrics", e);
        }

        StringBuilder aiResponse = new StringBuilder();

        streamChat(messages, "chat",
                chunk -> {
                    aiResponse.append(chunk);
                    // Do NOT try-catch around emitter.send!
                    // If client disconnected, this will throw an exception which will propagate to
                    // executeCoreStream's while loop, safely terminating the background processing.
                    try {
                        emitter.send(
                                SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                    } catch (java.io.IOException | IllegalStateException e) {
                        // Re-throw as RuntimeException to ensure it breaks out of the streaming reader
                        // loop in executeCoreStream
                        throw new RuntimeException("SSE connection broken", e);
                    }
                },
                () -> {
                    // 5. 聊天完成，保存 AI 回复 (Save AI Message on Complete)
                    try {
                        aiChatHistoryService.saveMessage(sessionId, "assistant", aiResponse.toString());
                        try {
                            emitter.send(SseEmitter.event().data("[DONE]"));
                            emitter.complete();
                        } catch (Exception e) {
                            log.warn("Failed to send terminal [DONE] or complete emitter (client likely closed): {}",
                                    e.getMessage());
                        }
                    } catch (Exception e) {
                        log.error("Failed to save message on completion", e);
                    }
                },
                e -> {
                    // 6. Handle Error - Also save partial response if possible
                    try {
                        if (aiResponse.length() > 0) {
                            log.info("Saving partial AI response before error/disconnect: {} chars",
                                    aiResponse.length());
                            aiChatHistoryService.saveMessage(sessionId, "assistant", aiResponse.toString());
                        }

                        try {
                            emitter.send(SseEmitter.event()
                                    .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                            emitter.completeWithError(e);
                        } catch (Exception ex) {
                            log.warn("Failed to send error event to emitter (client likely closed): {}",
                                    ex.getMessage());
                        }
                    } catch (Exception ex) {
                        log.error("Failed in error callback", ex);
                    }
                });
    }

    /**
     * 简单估算 Token 数 (按字符数/4)
     */
    private int estimateTokens(String text) {
        if (text == null || text.isEmpty())
            return 0;
        return text.length() / 4;
    }

    /**
     * 检查并压缩上下文 (Adaptive Context Summarization)
     * 如果历史消息 Token 超过阈值，则触发压缩
     * 
     * @return true if summarization occurred
     */
    private boolean checkAndSummarizeContext(String sessionId, SseEmitter emitter) {
        List<com.example.urgs_api.ai.entity.AiChatMessage> history = aiChatHistoryService.getSessionMessages(sessionId);
        if (history.isEmpty())
            return false;

        // 估算当前所有消息的 Token 总数
        long totalTokens = estimateTokens(history.stream().map(com.example.urgs_api.ai.entity.AiChatMessage::getContent)
                .reduce("", String::concat));

        // 只有超过阈值才触发 (default 80%, testing 20%)
        if (totalTokens < MAX_CONTEXT_TOKENS * TRIGGER_THRESHOLD) {
            return false;
        }

        // 触发压缩状态通知 (Trigger Compression)
        try {
            emitter.send(SseEmitter.event().name("status").data("compressing"));
            emitter.send(SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("status", "compressing"))));
        } catch (Exception e) {
            log.warn("Failed to send status event", e);
        }

        log.info("Triggering context summarization for session {}", sessionId);

        // 确保至少有足够的历史消息可供压缩 (除保留的最近几轮外)
        int keepCount = KEEP_RECENT_ROUNDS * 2; // User + Assistant 算作一轮，所以 * 2
        if (history.size() <= keepCount)
            return false;

        // 截取需要压缩的“旧消息”
        List<com.example.urgs_api.ai.entity.AiChatMessage> toSummarize = history.subList(0, history.size() - keepCount);

        StringBuilder oldContent = new StringBuilder();
        for (com.example.urgs_api.ai.entity.AiChatMessage msg : toSummarize) {
            oldContent.append(msg.getRole()).append(": ").append(msg.getContent()).append("\n");
        }

        // 获取可能已存在的旧摘要
        com.example.urgs_api.ai.entity.AiChatSession session = aiChatHistoryService.getSession(sessionId);
        String existingSummary = session != null ? session.getSummary() : "";

        // 构建压缩用的 Prompt (包含旧摘要 + 待压缩消息)
        String systemPrompt = "你是一个专业的对话记录员。你的任务是将一段过长的对话历史压缩成简练的'前情提要'。要求：保留关键信息：必须保留代码中的关键变量名、用户提到的具体需求、已经达成的结论。第三人称叙述：例如'用户询问了...助手建议...'。极度精简：去除客套话（如'你好'、'谢谢'），字数控制在原始文本的 20% 以内。增量更新：如果输入中已经包含了之前的'前情提要'，请将其与新的对话内容合并更新。";
        String userPrompt = (existingSummary != null && !existingSummary.isEmpty()
                ? "之前的【前情提要】:\n" + existingSummary + "\n\n"
                : "") +
                "需要压缩的旧对话:\n" + oldContent.toString();

        // 调用 AI 生成新摘要
        String newSummary = chat(systemPrompt, userPrompt);

        // 更新数据库中的 summary 字段
        if (newSummary != null && !newSummary.isEmpty()) {
            aiChatHistoryService.updateSessionSummary(sessionId, newSummary.trim());
            return true;
        }

        return false;
    }

    /**
     * 构建上下文消息列表
     * 逻辑：System Prompt + [Summary] + Recent History (Pruned)
     */
    private List<Map<String, String>> buildContextMessages(String systemPrompt,
            List<com.example.urgs_api.ai.entity.AiChatMessage> history, String sessionSummary) {
        List<Map<String, String>> messages = new java.util.LinkedList<>();

        // Add System Prompt
        messages.add(Map.of("role", "system", "content", systemPrompt));

        // Add Summary if exists
        if (sessionSummary != null && !sessionSummary.isEmpty()) {
            messages.add(Map.of("role", "system", "content", "【前情提要】：" + sessionSummary));
        }

        // Add History with smart pruning logic matching the Keep Recent Rounds
        // If we have a summary, we likely only need the recent rounds.
        // But for safety, we simply add the history. The 'checkAndSummarize' happens
        // *before* this,
        // so if it ran, we conceptually "removed" the old messages.
        // HOWEVER, we are fetching the FULL history again from DB in step 3.
        // We must ensure we don't duplicate the content we just summarized.
        // Wait, `checkAndSummarize` updates the summary in the DB, but it DOES NOT
        // delete the old messages from the DB (soft delete maybe?).
        // The PRD says "Replacement". This implies we should *ignore* the old messages
        // when verifying the context.

        // Correct Logic:
        // If we have a valid summary, we ideally essentially "skip" the old messages
        // when building the context for the model.
        // We define "Old" as anything before the last KEEP_RECENT_ROUNDS * 2.
        // But if we didn't summarize (threshold not met), we include everything (up to
        // hard limit).

        int keepRecent = KEEP_RECENT_ROUNDS * 2;
        List<com.example.urgs_api.ai.entity.AiChatMessage> effectiveHistory = history;

        // 如果存在摘要 (Summary)，则只保留最近几轮 (Keep Recent)，旧的由摘要代替
        // 否则使用全部历史 (会受限于 Token 检查)
        if (sessionSummary != null && !sessionSummary.isEmpty() && history.size() > keepRecent) {
            // 截取列表，只保留最后 keepRecent 条
            effectiveHistory = history.subList(Math.max(0, history.size() - keepRecent), history.size());
        }

        for (com.example.urgs_api.ai.entity.AiChatMessage msg : effectiveHistory) {
            messages.add(Map.of("role", msg.getRole(), "content", msg.getContent() != null ? msg.getContent() : ""));
        }

        return messages;
    }

    // Internal helper for SSE Emitter non-persistence
    private void streamChat(List<Map<String, String>> messages, String requestType, SseEmitter emitter) {
        executor.submit(() -> {
            try {
                streamChat(messages, requestType,
                        chunk -> {
                            try {
                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                            } catch (Exception e) {
                                log.error("Failed to send SSE event", e);
                            }
                        },
                        () -> {
                            try {
                                emitter.send(SseEmitter.event().data("[DONE]"));
                                emitter.complete();
                            } catch (Exception e) {
                                log.error("Failed to complete SSE", e);
                            }
                        },
                        e -> {
                            try {
                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                                emitter.completeWithError(e);
                            } catch (Exception ex) {
                                log.error("Failed to send error event", ex);
                            }
                        });
            } catch (Exception e) {
                log.error("Stream chat failed", e);
                emitter.completeWithError(e);
            }
        });
    }

    @Override
    public void streamChat(String systemPrompt, String userPrompt,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {
        // Legacy support
        List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt));
        streamChat(messages, "chat", chunkConsumer, onComplete, onError);
    }

    /**
     * 流式聊天（带请求类型）- Missing Overload
     */
    public void streamChat(String systemPrompt, String userPrompt, String requestType,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt));
        streamChat(messages, requestType, chunkConsumer, onComplete, onError);
    }

    /**
     * Core streaming with full messages list
     */
    public void streamChat(List<Map<String, String>> messages, String requestType,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {

        executor.submit(() -> {
            executeCoreStream(messages, requestType, chunkConsumer, onComplete, onError);
        });
    }

    private void executeCoreStream(List<Map<String, String>> messages, String requestType,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {

        AiApiConfig config = null;
        AtomicInteger promptTokens = new AtomicInteger(0);
        AtomicInteger completionTokens = new AtomicInteger(0);
        boolean success = false;
        String errorMessage = null;

        try {
            config = aiApiConfigService.getDefaultConfig();
            if (config == null) {
                throw new RuntimeException("未配置默认 AI API，请在系统管理中配置");
            }

            String endpoint = config.getEndpoint();
            if (!endpoint.endsWith("/")) {
                endpoint += "/";
            }
            endpoint += "chat/completions";

            // Build request body
            Map<String, Object> requestBody = Map.of(
                    "model", config.getModel(),
                    "messages", messages,
                    "stream", true,
                    "stream_options", Map.of("include_usage", true),
                    "max_tokens", config.getMaxTokens() != null ? config.getMaxTokens() : 4096,
                    "temperature", config.getTemperature() != null ? config.getTemperature() : 0.7);

            String jsonBody = objectMapper.writeValueAsString(requestBody);

            // log.info("Sending Chat Request with {} messages", messages.size());

            // Create connection
            HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
            conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + config.getApiKey());
            conn.setRequestProperty(HttpHeaders.ACCEPT, "text/event-stream");
            conn.setDoOutput(true);
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(120000);

            // Send request
            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            if (responseCode != 200) {
                // Error handling
                String errorBody = new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
                throw new RuntimeException("AI API 调用失败: " + responseCode + " - " + errorBody);
            }

            // Read streaming response
            try (BufferedReader reader = new BufferedReader(
                    new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
                String line;
                while ((line = reader.readLine()) != null) {
                    if (line.startsWith("data: ")) {
                        String data = line.substring(6).trim();
                        if ("[DONE]".equals(data)) {
                            log.info("Stream received [DONE]");
                            break;
                        }
                        try {
                            JsonNode node = objectMapper.readTree(data);

                            // Usage parsing
                            JsonNode usageNode = node.get("usage");
                            if (usageNode != null) {
                                if (usageNode.has("prompt_tokens"))
                                    promptTokens.set(usageNode.get("prompt_tokens").asInt());
                                if (usageNode.has("completion_tokens"))
                                    completionTokens.set(usageNode.get("completion_tokens").asInt());
                            }

                            // Content parsing
                            JsonNode choices = node.get("choices");
                            if (choices != null && choices.isArray() && !choices.isEmpty()) {
                                JsonNode delta = choices.get(0).get("delta");
                                if (delta != null) {
                                    if (delta.has("content")) {
                                        String content = delta.get("content").asText();
                                        if (content != null && !content.isEmpty()) {
                                            chunkConsumer.accept(content);
                                        }
                                    } else if (delta.has("reasoning_content")) {
                                        // Handle reasoning content (Doubao/DeepSeek)
                                        String reasoning = delta.get("reasoning_content").asText();
                                        if (reasoning != null && !reasoning.isEmpty()) {
                                            log.debug("Got reasoning chunk");
                                            log.info("Received reasoning content (hidden from user): {}",
                                                    reasoning.length());
                                        }
                                    }
                                }
                            }
                        } catch (Exception e) {
                            log.warn("Failed to parse SSE data: {}", data, e);
                        }
                    }
                }
            }

            success = true;
            onComplete.run();

        } catch (Exception e) {
            log.error("AI stream chat error", e);
            errorMessage = e.getMessage();
            onError.accept(e);
        } finally {
            // Record Usage
            if (config != null) {
                try {
                    // Approximate prompt tokens if not returned
                    int estimatedPromptTokens = promptTokens.get();
                    if (estimatedPromptTokens <= 0) {
                        // Very rough estimate based on messages list string
                        estimatedPromptTokens = messages.toString().length() / 4;
                    }

                    aiUsageLogService.recordUsage(
                            config.getId(),
                            config.getModel(),
                            estimatedPromptTokens,
                            completionTokens.get(),
                            requestType,
                            success,
                            errorMessage);
                } catch (Exception e) {
                    log.error("Failed to record AI usage", e);
                }
            }
        }
    }

}
