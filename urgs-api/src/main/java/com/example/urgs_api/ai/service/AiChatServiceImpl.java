package com.example.urgs_api.ai.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.example.urgs_api.ai.client.DeepAgentsRouterClient;
import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.service.agent.AgentAppBuildModeHandler;
import com.example.urgs_api.ai.service.agent.DeepAgentsBuildModeHandler;
import com.example.urgs_api.ai.service.agent.DifyBuildModeHandler;
import com.example.urgs_api.ai.service.agent.RagBuildModeHandler;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
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
    private AiChatHistoryService aiChatHistoryService; // Inject history service

    @Autowired
    private com.example.urgs_api.ai.repository.AgentRepository agentRepository;

    @Autowired
    private AgentAppBuildModeHandler agentAppBuildModeHandler;

    @Autowired
    private DeepAgentsBuildModeHandler deepAgentsBuildModeHandler;

    @Autowired
    private RagBuildModeHandler ragBuildModeHandler;

    @Autowired
    private DifyBuildModeHandler difyBuildModeHandler;

    @Autowired
    private DeepAgentsRouterClient deepAgentsRouterClient;

    @Autowired
    private AiAgentRunService aiAgentRunService;

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

        com.example.urgs_api.ai.entity.AiChatSession sessionInfo = resolveSession(sessionId);
        com.example.urgs_api.ai.entity.Agent sessionAgent = sessionInfo != null && sessionInfo.getAgentId() != null
                ? agentRepository.selectById(sessionInfo.getAgentId())
                : null;
        String runId = aiAgentRunService.createRun(sessionId, sessionInfo == null ? null : sessionInfo.getUserId(),
                sessionAgent, userPrompt);
        sendAgentEvent(runId, sessionId, sessionAgent, emitter, "routing_started", "thinking",
                "任务识别", "正在识别任务类型和可用助手", Map.of("manual", sessionAgent != null), "RUNNING");

        if (sessionAgent == null) {
            List<Agent> routingAgents = listRoutingAgents();
            try {
                DeepAgentsRouterClient.RouteResult routeResult = deepAgentsRouterClient.route(userPrompt, routingAgents);
                sessionAgent = findAgentByCode(routingAgents, routeResult.agentCode());
                if (sessionAgent == null) {
                    failBeforeExecution(runId, sessionId, emitter, "Router Agent 返回了不存在或未启用的 Agent: " + routeResult.agentCode(),
                            Map.of("agentCode", routeResult.agentCode()));
                    return;
                }
                aiAgentRunService.updateRouting(runId, sessionAgent, routeResult.taskType(), routeResult.confidence());
                sendAgentEvent(runId, sessionId, sessionAgent, emitter, "routing_completed", "status",
                        "任务识别完成", "Router Agent 已完成任务分发",
                        routePayload(routeResult, sessionAgent), "RUNNING");
                sendAgentEvent(runId, sessionId, sessionAgent, emitter, "agent_selected", "status",
                        "Agent 选择", selectedAgentDescription(routeResult, sessionAgent),
                        routePayload(routeResult, sessionAgent), "RUNNING");
            } catch (Exception e) {
                String errorMessage = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
                failBeforeExecution(runId, sessionId, emitter, "Router Agent 分发失败: " + errorMessage,
                        Map.of("error", errorMessage));
                return;
            }
            if (sessionInfo != null && sessionInfo.getAgentId() == null) {
                sessionInfo.setAgentId(sessionAgent.getId());
                aiChatHistoryService.updateSession(sessionInfo);
            }
        } else {
            aiAgentRunService.updateRouting(runId, sessionAgent, "manual", 1.0);
            sendAgentEvent(runId, sessionId, sessionAgent, emitter, "routing_completed", "status",
                    "任务识别完成", "已检测到手动选择的 Agent，跳过 Router Agent",
                    manualRoutePayload(sessionAgent), "RUNNING");
            sendAgentEvent(runId, sessionId, sessionAgent, emitter, "agent_selected", "status",
                    "Agent 选择", "已使用手动选择的 Agent：" + sessionAgent.getName(),
                    manualRoutePayload(sessionAgent),
                    "RUNNING");
        }

        if (agentAppBuildModeHandler.supports(sessionAgent)) {
            sendAgentEvent(runId, sessionId, sessionAgent, emitter, "model_stream", "status",
                    "生成中", "已进入 Agent App 执行流程", Map.of("buildMode", "AGENT_APP"), "RUNNING");
            agentAppBuildModeHandler.streamWithPersistence(sessionId, sessionAgent, userPrompt, agentAppSkillAppCode,
                    agentAppSkillCode, conversationContext, emitter, runId);
            return;
        }
        if (deepAgentsBuildModeHandler.supports(sessionAgent)) {
            deepAgentsBuildModeHandler.streamWithPersistence(sessionId, sessionAgent, systemPrompt, userPrompt,
                    conversationContext, emitter, runId);
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
        final boolean[] modelStreamRecorded = { false };
        final com.example.urgs_api.ai.entity.Agent activeAgent = sessionAgent;

        streamChat(sessionId, messages, "chat",
                chunk -> {
                    aiResponse.append(chunk);
                    if (!modelStreamRecorded[0]) {
                        modelStreamRecorded[0] = true;
                        sendAgentEvent(runId, sessionId, activeAgent, emitter, "model_stream", "status",
                                "生成中", "模型开始流式输出", Map.of("requestType", "chat"), "RUNNING");
                    }
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
                        aiAgentRunService.recordEvent(runId, sessionId, activeAgent, "run_completed", "完成",
                                "模型响应已完成", Map.of("responseLength", aiResponse.length()), "COMPLETED");
                        aiAgentRunService.completeRun(runId);
                        sendAgentEvent(runId, sessionId, activeAgent, emitter, "ui_completed", "status",
                                "完成", "回答已生成", Map.of("responseLength", aiResponse.length()), "COMPLETED");
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
                        aiAgentRunService.recordEvent(runId, sessionId, activeAgent, "run_failed", "执行失败",
                                e.getMessage(), Map.of("responseLength", aiResponse.length()), "FAILED");
                        aiAgentRunService.failRun(runId, e.getMessage());

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

    private void sendAgentEvent(String runId, String sessionId, com.example.urgs_api.ai.entity.Agent agent,
            SseEmitter emitter, String eventType, String type, String title, String content,
            Map<String, Object> payload, String status) {
        aiAgentRunService.recordEvent(runId, sessionId, agent, eventType, title, content, payload, status);
        try {
            java.util.Map<String, Object> event = new java.util.LinkedHashMap<>();
            event.put("type", type);
            event.put("title", title);
            if (content != null && !content.isBlank()) {
                event.put("content", content);
            }
            if (payload != null) {
                event.putAll(payload);
            }
            emitter.send(SseEmitter.event().name("agent").data(objectMapper.writeValueAsString(event)));
        } catch (Exception e) {
            log.warn("Failed to send agent event {} for session {}", eventType, sessionId, e);
        }
    }

    private void failBeforeExecution(String runId, String sessionId, SseEmitter emitter, String message,
            Map<String, Object> payload) {
        aiAgentRunService.recordEvent(runId, sessionId, null, "router_failed", "任务分发失败", message, payload, "FAILED");
        aiAgentRunService.failRun(runId, message);
        try {
            emitter.send(SseEmitter.event().name("agent")
                    .data(objectMapper.writeValueAsString(Map.of(
                            "type", "status",
                            "title", "任务分发失败",
                            "content", message))));
            emitter.send(SseEmitter.event().data(objectMapper.writeValueAsString(Map.of("error", message))));
            emitter.complete();
        } catch (Exception e) {
            log.warn("Failed to send router failure event for session {}", sessionId, e);
        }
    }

    private List<Agent> listRoutingAgents() {
        return agentRepository.selectList(new QueryWrapper<Agent>()
                .eq("status", 1)
                .isNotNull("agent_code")
                .ne("agent_code", "")
                .orderByAsc("sort_order")
                .orderByDesc("id"));
    }

    private Agent findAgentByCode(List<Agent> agents, String agentCode) {
        if (agents == null || agentCode == null || agentCode.isBlank()) {
            return null;
        }
        for (Agent agent : agents) {
            if (agentCode.equals(agent.getAgentCode())) {
                return agent;
            }
        }
        return null;
    }

    private Map<String, Object> routePayload(DeepAgentsRouterClient.RouteResult result, Agent agent) {
        java.util.Map<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("intent", result.taskType());
        payload.put("confidence", result.confidence());
        payload.put("reason", result.reason());
        payload.put("requiresCollaboration", result.requiresCollaboration());
        payload.put("collaborationPlan", result.collaborationPlan());
        if (agent != null) {
            payload.put("agentId", agent.getId());
            payload.put("agentCode", agent.getAgentCode());
            payload.put("agentName", agent.getName());
            payload.put("buildMode", agent.getBuildMode());
        }
        return payload;
    }

    private Map<String, Object> manualRoutePayload(Agent agent) {
        java.util.Map<String, Object> payload = new java.util.LinkedHashMap<>();
        payload.put("manual", true);
        if (agent != null) {
            payload.put("agentId", agent.getId());
            payload.put("agentCode", agent.getAgentCode());
            payload.put("agentName", agent.getName());
            payload.put("buildMode", agent.getBuildMode());
        }
        return payload;
    }

    private String selectedAgentDescription(DeepAgentsRouterClient.RouteResult result, Agent agent) {
        int confidence = (int) Math.round(result.confidence() * 100);
        return "已选择 " + agent.getName() + "，置信度 " + confidence + "%：" + result.reason();
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

        try {
            com.example.urgs_api.ai.entity.AiChatSession sessionInfo = resolveSession(sessionId);
            com.example.urgs_api.ai.entity.Agent agent = sessionInfo != null && sessionInfo.getAgentId() != null
                    ? agentRepository.selectById(sessionInfo.getAgentId())
                    : null;
            if (difyBuildModeHandler.supports(agent)) {
                difyBuildModeHandler.stream(sessionId, sessionInfo, agent, messages, chunkConsumer);
                onComplete.run();
                return;
            }

            String systemPrompt = extractSystemPrompt(messages);
            deepAgentsBuildModeHandler.streamDefault(systemPrompt, messages, chunkConsumer, onComplete, onError);
        } catch (Exception e) {
            log.error("AI stream chat error", e);
            onError.accept(e);
        }
    }

    private String extractSystemPrompt(List<Map<String, String>> messages) {
        if (messages == null || messages.isEmpty()) {
            return "You are a helpful assistant.";
        }
        Map<String, String> first = messages.get(0);
        if ("system".equals(first.get("role"))) {
            return first.getOrDefault("content", "You are a helpful assistant.");
        }
        return "You are a helpful assistant.";
    }

}
