package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.agent.AgentAppBuildModeHandler;
import com.example.urgs_api.ai.service.agent.DifyBuildModeHandler;
import com.example.urgs_api.ai.service.agent.RagBuildModeHandler;
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
    private AgentAppBuildModeHandler agentAppBuildModeHandler;

    @Autowired
    private RagBuildModeHandler ragBuildModeHandler;

    @Autowired
    private DifyBuildModeHandler difyBuildModeHandler;

    @Override
    public String chat(String systemPrompt, String userPrompt) {
        return chat(null, systemPrompt, userPrompt, "chat");
    }

    /**
     * 同步聊天（带请求类型）
     */
    public String chat(String sessionId, String systemPrompt, String userPrompt, String requestType) {
        List<Map<String, String>> messages = List.of(
                Map.of("role", "system", "content", systemPrompt),
                Map.of("role", "user", "content", userPrompt));
        StringBuilder result = new StringBuilder();
        executeCoreStream(sessionId, messages, requestType, result::append, () -> {
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
        streamChat(null, messages, requestType, emitter);
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
            String agentAppSkillAppCode, String agentAppSkillCode, List<Map<String, String>> conversationContext,
            SseEmitter emitter) {
        log.info("Starting streamChatWithPersistence for session: {}", sessionId);

        // 1. 保存用户消息 (Save User Message)
        aiChatHistoryService.saveMessage(sessionId, "user", userPrompt);

        com.example.urgs_api.ai.entity.Agent sessionAgent = resolveSessionAgent(sessionId);
        if (agentAppBuildModeHandler.supports(sessionAgent)) {
            agentAppBuildModeHandler.streamWithPersistence(sessionId, sessionAgent, userPrompt, agentAppSkillAppCode,
                    agentAppSkillCode, conversationContext, emitter);
            return;
        }

        String contextAugmentation = "";
        if (sessionAgent != null) {
            log.info("Checking Agent Configuration - ID: {}, Name: {}, Mode: {}, KB: {}",
                    sessionAgent.getId(), sessionAgent.getName(), sessionAgent.getBuildMode(), sessionAgent.getKnowledgeBase());
            if (ragBuildModeHandler.supports(sessionAgent)) {
                RagBuildModeHandler.RagPreparation preparation = ragBuildModeHandler
                        .prepare(sessionAgent, systemPrompt, userPrompt, emitter);
                systemPrompt = preparation.systemPrompt();
                contextAugmentation = preparation.contextAugmentation();
            } else if (sessionAgent.getSystemPrompt() != null && !sessionAgent.getSystemPrompt().isBlank()) {
                systemPrompt = sessionAgent.getSystemPrompt();
            }
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

        if (!contextAugmentation.isEmpty()) {
            log.info("Injecting RAG Context into Request Messages");
            ragBuildModeHandler.applyContextToMessages(sessionAgent, messages, contextAugmentation);
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

        streamChat(sessionId, messages, "chat",
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
                            emitter.complete();
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
        String newSummary = chat(sessionId, systemPrompt, userPrompt, "chat");

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

    private com.example.urgs_api.ai.entity.Agent resolveSessionAgent(String sessionId) {
        try {
            com.example.urgs_api.ai.entity.AiChatSession sessionInfo = resolveSession(sessionId);
            if (sessionInfo != null && sessionInfo.getAgentId() != null) {
                return agentRepository.selectById(sessionInfo.getAgentId());
            }
        } catch (Exception e) {
            log.warn("Failed to resolve session agent for session {}", sessionId, e);
        }
        return null;
    }

    private com.example.urgs_api.ai.entity.AiChatSession resolveSession(String sessionId) {
        if (sessionId == null || sessionId.isBlank()) {
            return null;
        }
        return aiChatHistoryService.getSession(sessionId);
    }

    // Internal helper for SSE Emitter non-persistence
    private void streamChat(String sessionId, List<Map<String, String>> messages, String requestType,
            SseEmitter emitter) {
        executor.submit(() -> {
            try {
                streamChat(sessionId, messages, requestType,
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
                                emitter.complete();
                            } catch (Exception ex) {
                                log.error("Failed to send error event", ex);
                            }
                        });
            } catch (Exception e) {
                log.error("Stream chat failed", e);
                try {
                    emitter.send(
                            SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                } catch (Exception ex) {
                    log.error("Failed to send error event", ex);
                }
                emitter.complete();
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
        streamChat(null, messages, "chat", chunkConsumer, onComplete, onError);
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
        streamChat(null, messages, requestType, chunkConsumer, onComplete, onError);
    }

    /**
     * Core streaming with full messages list
     */
    public void streamChat(String sessionId, List<Map<String, String>> messages, String requestType,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {

        executor.submit(() -> {
            executeCoreStream(sessionId, messages, requestType, chunkConsumer, onComplete, onError);
        });
    }

    private void executeCoreStream(String sessionId, List<Map<String, String>> messages, String requestType,
            Consumer<String> chunkConsumer,
            Runnable onComplete,
            Consumer<Exception> onError) {

        AiApiConfig config = null;
        AtomicInteger promptTokens = new AtomicInteger(0);
        AtomicInteger completionTokens = new AtomicInteger(0);
        boolean success = false;
        String errorMessage = null;

        try {
            com.example.urgs_api.ai.entity.AiChatSession sessionInfo = resolveSession(sessionId);
            com.example.urgs_api.ai.entity.Agent agent = sessionInfo != null && sessionInfo.getAgentId() != null
                    ? agentRepository.selectById(sessionInfo.getAgentId())
                    : null;
            if (difyBuildModeHandler.supports(agent)) {
                difyBuildModeHandler.stream(sessionId, sessionInfo, agent, messages, chunkConsumer);
                success = true;
                onComplete.run();
                return;
            }

            // --- Fallback to standard OpenAI compatible API ---
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
                                    if (delta.has("content") && !delta.get("content").isNull()) {
                                        String content = delta.get("content").asText();
                                        if (content != null && !content.isEmpty()) {
                                            chunkConsumer.accept(content);
                                        }
                                    } else if (delta.has("reasoning_content") && !delta.get("reasoning_content").isNull()) {
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
