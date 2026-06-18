package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.ai.client.DeepAgentsOrchestratorClient;
import com.example.urgs_api.ai.entity.AiChatMessage;
import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.service.AiAgentRunService;
import com.example.urgs_api.ai.service.AiChatHistoryService;
import com.example.urgs_api.ai.service.AiTokenBudgetService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.function.Consumer;

@Component
public class DeepAgentsBuildModeHandler {

    private static final Logger log = LoggerFactory.getLogger(DeepAgentsBuildModeHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();
    private static final ExecutorService executor = Executors.newCachedThreadPool();
    private static final int KEEP_RECENT_ROUNDS = 3;

    private final AiChatHistoryService aiChatHistoryService;
    private final AiAgentRunService aiAgentRunService;
    private final AiTokenBudgetService aiTokenBudgetService;
    private final String deepAgentsBaseUrl;
    private final DeepAgentsOrchestratorClient orchestratorClient;
    private final String internalApiAuthHeader;
    private final String internalApiAuthPrefix;
    private final String internalApiAuthToken;

    public DeepAgentsBuildModeHandler(
            AiChatHistoryService aiChatHistoryService,
            AiAgentRunService aiAgentRunService,
            AiTokenBudgetService aiTokenBudgetService,
            DeepAgentsOrchestratorClient orchestratorClient,
            @Value("${urgs.deepagents.base-url:http://127.0.0.1:8003}") String deepAgentsBaseUrl,
            @Value("${urgs.internal-api.auth-header:Authorization}") String internalApiAuthHeader,
            @Value("${urgs.internal-api.auth-prefix:Bearer }") String internalApiAuthPrefix,
            @Value("${urgs.internal-api.auth-token:}") String internalApiAuthToken) {
        this.aiChatHistoryService = aiChatHistoryService;
        this.aiAgentRunService = aiAgentRunService;
        this.aiTokenBudgetService = aiTokenBudgetService;
        this.orchestratorClient = orchestratorClient;
        this.deepAgentsBaseUrl = deepAgentsBaseUrl;
        this.internalApiAuthHeader = internalApiAuthHeader;
        this.internalApiAuthPrefix = internalApiAuthPrefix;
        this.internalApiAuthToken = internalApiAuthToken;
    }

    public boolean supports(Agent agent) {
        return agent != null && "DEEPAGENTS".equalsIgnoreCase(agent.getBuildMode());
    }

    public record RoutingInfo(String agentCode, String agentName, long agentId, double confidence,
            String reason, String taskType, boolean isComplex, String buildMode) {
    }

    /**
     * DEEPAGENTS 编排入口：调用 /v1/orchestrator/stream，由 DeepAgents 侧完成
     * Input Guard -> Router -> Planner -> Worker -> Reviewer -> 返工 -> Finalizer 全流程。
     * API 仅作为适配器：转发 SSE、持久化事件、处理 quality_risk 与非 DEEPAGENTS 的 handoff。
     *
     * @param preselectedAgent 手动预选 Agent；null 表示由编排内部 Router 路由
     * @param catalog          全部启用 Agent 目录，供编排 Router/Planner 选择
     * @param routingCallback  路由完成回调（更新 run 路由信息与 session agent）
     * @param legacyDispatch   handoff 回调：编排路由到非 DEEPAGENTS Agent 时，交回遗留执行路径
     */
    public void streamWithPersistence(String sessionId, Agent preselectedAgent, String systemPrompt,
            String userPrompt, List<Map<String, String>> conversationContext, List<Agent> catalog,
            SseEmitter emitter, String runId, Consumer<RoutingInfo> routingCallback,
            Consumer<Agent> legacyDispatch) {
        executor.submit(() -> {
            StringBuilder responseBuilder = new StringBuilder();
            boolean[] streamStarted = { false };
            final Agent[] activeAgent = { preselectedAgent };
            try {
                emitter.send(SseEmitter.event().name("status").data("deepagents_orchestrating"));

                List<Map<String, String>> messages = buildMessages(sessionId, userPrompt, conversationContext);
                int used = aiTokenBudgetService.estimateMessages(messages);
                int limit = aiTokenBudgetService.resolveContextWindow(preselectedAgent);
                emitter.send(SseEmitter.event().name("metrics")
                        .data(objectMapper.writeValueAsString(Map.of("used", used, "limit", limit))));

                Map<String, Object> body = buildOrchestratorRequest(
                        resolveSystemPrompt(preselectedAgent, systemPrompt), messages, preselectedAgent, catalog);

                final boolean[] handoff = { false };
                final Agent[] handoffAgent = { null };

                orchestratorClient.stream(body, (eventName, data) -> {
                    switch (eventName) {
                        case "input_guard":
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0],
                                    "input_guard_" + data.path("status").asText("passed"),
                                    "Input Guard", data.path("reason").asText(""), data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "routing":
                            handleRoutingEvent(runId, sessionId, catalog, data, activeAgent,
                                    routingCallback, emitter);
                            break;
                        case "planning":
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0],
                                    "planning_" + data.path("status").asText("started"),
                                    "Planner 拆解", data.path("reason").asText(""), data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "worker":
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0],
                                    "worker_" + data.path("status").asText("started"),
                                    "Worker 执行", data.path("task").asText(""), data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "content":
                            String content = data.path("content").asText("");
                            if (!content.isEmpty()) {
                                responseBuilder.append(content);
                                if (!streamStarted[0]) {
                                    streamStarted[0] = true;
                                    aiAgentRunService.recordEvent(runId, sessionId, activeAgent[0],
                                            "model_stream", "生成中", "编排开始流式输出",
                                            Map.of("buildMode", "DEEPAGENTS"), "RUNNING");
                                }
                                try {
                                    emitter.send(SseEmitter.event()
                                            .data(objectMapper.writeValueAsString(Map.of("content", content))));
                                } catch (Exception e) {
                                    throw new RuntimeException("SSE connection broken", e);
                                }
                            }
                            break;
                        case "agent":
                            recordDeepAgentsEvent(runId, sessionId, activeAgent[0], data);
                            try {
                                emitter.send(SseEmitter.event().name("agent")
                                        .data(objectMapper.writeValueAsString(data)));
                            } catch (Exception e) {
                                throw new RuntimeException("SSE connection broken", e);
                            }
                            break;
                        case "review":
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0],
                                    "review_" + data.path("status").asText("passed"),
                                    "Reviewer 验收", data.path("reason").asText(""), data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "rework":
                            // 返工开始：清空已累积的首跑内容，最终只保留返工/Finalizer 产出
                            responseBuilder.setLength(0);
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0], "rework_started",
                                    "返工", data.path("reason").asText(""), data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "finalizing":
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0], "finalizing",
                                    "Finalizer 汇总", "", data, "RUNNING");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "quality_risk":
                            aiAgentRunService.markQualityRisk(runId);
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0], "quality_risk",
                                    "质量风险", data.path("reason").asText(""), data, "COMPLETED");
                            forwardAgentEvent(emitter, data);
                            break;
                        case "handoff":
                            handoff[0] = true;
                            handoffAgent[0] = findAgentByCode(catalog, data.path("agent_code").asText(""));
                            recordOrchestratorEvent(runId, sessionId, activeAgent[0], "handoff",
                                    "移交遗留执行", data.path("agent_code").asText(""), data, "RUNNING");
                            break;
                        case "done":
                            // 流结束后统一处理
                            break;
                        case "error":
                            throw new RuntimeException(data.path("error").asText("编排失败"));
                        default:
                            // 未知事件忽略
                    }
                });

                if (handoff[0] && handoffAgent[0] != null) {
                    // 交回遗留执行路径，由回调负责完成 emitter 与 run
                    Agent legacy = handoffAgent[0];
                    if (routingCallback != null) {
                        routingCallback.accept(new RoutingInfo(legacy.getAgentCode(), legacy.getName(),
                                legacy.getId() == null ? 0 : legacy.getId(), 1.0, "handoff", "handoff",
                                false, legacy.getBuildMode()));
                    }
                    legacyDispatch.accept(legacy);
                    return;
                }

                String response = responseBuilder.toString();
                aiChatHistoryService.saveMessage(sessionId, "assistant", response);
                aiAgentRunService.recordEvent(runId, sessionId, activeAgent[0], "run_completed", "完成",
                        "DeepAgents 编排已完成", Map.of("responseLength", response.length()), "COMPLETED");
                aiAgentRunService.completeRun(runId);
                emitter.send(SseEmitter.event().data("[DONE]"));
                emitter.complete();
            } catch (Exception e) {
                log.error("DeepAgents orchestration failed for session {}", sessionId, e);
                try {
                    String errorMessage = e.getMessage() == null ? e.getClass().getSimpleName() : e.getMessage();
                    String response = responseBuilder.toString();
                    if (!response.isBlank()) {
                        aiChatHistoryService.saveMessage(sessionId, "assistant", response);
                    }
                    aiAgentRunService.recordEvent(runId, sessionId, activeAgent[0], "run_failed", "执行失败",
                            errorMessage, Map.of("responseLength", response.length()), "FAILED");
                    aiAgentRunService.failRun(runId, errorMessage);
                    emitter.send(SseEmitter.event()
                            .data(objectMapper.writeValueAsString(Map.of("error", errorMessage))));
                    emitter.complete();
                } catch (Exception ex) {
                    log.warn("Failed to send DeepAgents error event", ex);
                }
            }
        });
    }

    private void handleRoutingEvent(String runId, String sessionId, List<Agent> catalog, JsonNode data,
            Agent[] activeAgent, Consumer<RoutingInfo> routingCallback, SseEmitter emitter) throws Exception {
        String agentCode = data.path("agent_code").asText("");
        Agent routed = findAgentByCode(catalog, agentCode);
        if (routed != null) {
            activeAgent[0] = routed;
        }
        RoutingInfo info = new RoutingInfo(agentCode, data.path("agent_name").asText(""),
                routed != null && routed.getId() != null ? routed.getId() : 0,
                data.path("confidence").asDouble(0.0), data.path("reason").asText(""),
                data.path("task_type").asText(""), data.path("is_complex").asBoolean(false),
                data.path("build_mode").asText(""));
        if (routingCallback != null) {
            routingCallback.accept(info);
        }
        aiAgentRunService.updateRouting(runId, routed, info.taskType(),
                info.confidence() >= 1.0 && "manual".equals(info.taskType()) ? 1.0 : info.confidence());
        aiAgentRunService.recordEvent(runId, sessionId, routed, "routing_completed", "任务识别完成",
                "Router Agent 已完成任务分发", objectMapper.convertValue(data, new TypeReference<Map<String, Object>>() {
                }), "RUNNING");
        aiAgentRunService.recordEvent(runId, sessionId, routed, "agent_selected", "Agent 选择",
                "已选择 " + info.agentName(), objectMapper.convertValue(data, new TypeReference<Map<String, Object>>() {
                }), "RUNNING");
        Map<String, Object> statusEvent = new java.util.LinkedHashMap<>();
        statusEvent.put("type", "status");
        statusEvent.put("title", "任务识别完成");
        statusEvent.put("content", "已选择 " + info.agentName() + "：" + info.reason());
        statusEvent.putAll(objectMapper.convertValue(data, new TypeReference<Map<String, Object>>() {
        }));
        emitter.send(SseEmitter.event().name("agent").data(objectMapper.writeValueAsString(statusEvent)));
    }

    private void forwardAgentEvent(SseEmitter emitter, JsonNode data) {
        try {
            emitter.send(SseEmitter.event().name("agent")
                    .data(objectMapper.writeValueAsString(data)));
        } catch (Exception e) {
            throw new RuntimeException("SSE connection broken", e);
        }
    }

    private void recordOrchestratorEvent(String runId, String sessionId, Agent agent, String eventType,
            String title, String content, JsonNode data, String status) {
        Map<String, Object> payload = objectMapper.convertValue(data, new TypeReference<Map<String, Object>>() {
        });
        aiAgentRunService.recordEvent(runId, sessionId, agent, eventType, title, content, payload, status);
    }

    private Agent findAgentByCode(List<Agent> catalog, String agentCode) {
        if (catalog == null || agentCode == null || agentCode.isBlank()) {
            return null;
        }
        for (Agent agent : catalog) {
            if (agentCode.equals(agent.getAgentCode())) {
                return agent;
            }
        }
        return null;
    }

    private Map<String, Object> buildOrchestratorRequest(String systemPrompt, List<Map<String, String>> messages,
            Agent preselectedAgent, List<Agent> catalog) {
        Map<String, Object> body = new java.util.LinkedHashMap<>();
        body.put("system_prompt", systemPrompt);
        body.put("messages", messages);
        if (preselectedAgent != null && preselectedAgent.getAgentCode() != null
                && !preselectedAgent.getAgentCode().isBlank()) {
            body.put("selected_agent_code", preselectedAgent.getAgentCode());
        }
        body.put("agents", serializeCatalog(catalog));
        Map<String, Object> configs = new java.util.LinkedHashMap<>();
        if (catalog != null) {
            for (Agent agent : catalog) {
                if (agent == null || !"DEEPAGENTS".equalsIgnoreCase(agent.getBuildMode())) {
                    continue;
                }
                Map<String, Object> cfg = new java.util.LinkedHashMap<>();
                cfg.put("system_prompt", agent.getSystemPrompt());
                List<String> memoryFiles = parseStringList(agent.getMemoryFiles());
                if (!memoryFiles.isEmpty()) {
                    cfg.put("memory_files", memoryFiles);
                }
                List<String> skillDirs = parseStringList(agent.getSkillDirs());
                if (!skillDirs.isEmpty()) {
                    cfg.put("skill_dirs", skillDirs);
                }
                List<String> toolAllowlist = parseStringList(agent.getToolAllowlist());
                if (!toolAllowlist.isEmpty()) {
                    cfg.put("tool_allowlist", toolAllowlist);
                }
                // 解析 policy_config：{"write":"allow","workspace_root":"/path"} 控制写权限与 per-agent 工作空间
                Map<String, Object> policy = parsePolicyConfig(agent.getPolicyConfig());
                if (Boolean.TRUE.equals(policy.get("allow_write"))) {
                    cfg.put("allow_write", true);
                }
                Object wsRoot = policy.get("workspace_root");
                if (wsRoot instanceof String ws && !ws.isBlank()) {
                    cfg.put("workspace_root", ws);
                }
                configs.put(agent.getAgentCode(), cfg);
            }
        }
        body.put("agent_configs", configs);
        return body;
    }

    private List<Map<String, Object>> serializeCatalog(List<Agent> catalog) {
        List<Map<String, Object>> items = new ArrayList<>();
        if (catalog == null) {
            return items;
        }
        for (Agent agent : catalog) {
            Map<String, Object> item = new java.util.LinkedHashMap<>();
            item.put("agent_code", agent.getAgentCode());
            item.put("agent_name", agent.getName());
            item.put("agent_type", agent.getAgentType());
            item.put("build_mode", agent.getBuildMode());
            item.put("description", agent.getDescription());
            item.put("capability_tags", agent.getCapabilityTags());
            item.put("routing_examples", agent.getRoutingExamples());
            item.put("sort_order", agent.getSortOrder());
            items.add(item);
        }
        return items;
    }

    public String invokeDefault(String systemPrompt, List<Map<String, String>> messages) throws Exception {
        StringBuilder response = new StringBuilder();
        streamDeepAgents(systemPrompt, normalizeConversationContext(messages), null, response::append, event -> {
        });
        return response.toString();
    }

    public void streamDefault(String systemPrompt, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer, Runnable onComplete, Consumer<Exception> onError) {
        try {
            streamDeepAgents(systemPrompt, normalizeConversationContext(messages), null, chunkConsumer, event -> {
            });
            onComplete.run();
        } catch (Exception e) {
            onError.accept(e);
        }
    }

    private List<Map<String, String>> buildMessages(String sessionId, String userPrompt,
            List<Map<String, String>> conversationContext) {
        List<Map<String, String>> messages = normalizeConversationContext(conversationContext);
        if (messages.isEmpty()) {
            messages = buildConversationContextFromHistory(sessionId, userPrompt);
        }
        messages = keepRecentConversationRounds(messages);

        String currentPrompt = nullToEmpty(userPrompt);
        if (!currentPrompt.isBlank()) {
            boolean alreadyIncluded = !messages.isEmpty()
                    && "user".equals(messages.get(messages.size() - 1).get("role"))
                    && currentPrompt.equals(messages.get(messages.size() - 1).get("content"));
            if (!alreadyIncluded) {
                messages = new ArrayList<>(messages);
                messages.add(Map.of("role", "user", "content", currentPrompt));
            }
        }
        return messages;
    }

    private void streamDeepAgents(String systemPrompt, List<Map<String, String>> messages, Agent agent,
            Consumer<String> chunkConsumer, Consumer<JsonNode> eventConsumer) throws Exception {
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/agents/stream";
        Map<String, Object> requestBody = buildDeepAgentsRequest(systemPrompt, messages, agent);
        String jsonBody = objectMapper.writeValueAsString(requestBody);

        HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "text/event-stream");
        applyInternalApiAuth(conn);
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(900000);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        int responseCode = conn.getResponseCode();
        if (responseCode < 200 || responseCode >= 300) {
            String responseBody = conn.getErrorStream() == null
                    ? ""
                    : new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
            throw new RuntimeException("DeepAgents 流式调用失败: " + responseCode + " - " + responseBody);
        }

        String currentEvent = "message";
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (line.startsWith("event:")) {
                    currentEvent = line.substring(6).trim();
                    continue;
                }
                if (!line.startsWith("data:")) {
                    if (line.isBlank()) {
                        currentEvent = "message";
                    }
                    continue;
                }
                String data = line.substring(5).trim();
                if (data.isBlank()) {
                    continue;
                }
                if ("done".equals(currentEvent)) {
                    break;
                }
                if ("error".equals(currentEvent)) {
                    JsonNode errorNode = objectMapper.readTree(data);
                    throw new RuntimeException(errorNode.path("error").asText("DeepAgents 调用失败"));
                }
                JsonNode node = objectMapper.readTree(data);
                if ("content".equals(currentEvent)) {
                    String content = node.path("content").asText("");
                    if (!content.isEmpty()) {
                        chunkConsumer.accept(content);
                    }
                } else if ("agent".equals(currentEvent)) {
                    eventConsumer.accept(node);
                }
            }
        }
    }

    private Map<String, Object> buildDeepAgentsRequest(String systemPrompt, List<Map<String, String>> messages,
            Agent agent) {
        Map<String, Object> requestBody = new java.util.LinkedHashMap<>();
        requestBody.put("system_prompt", systemPrompt);
        requestBody.put("messages", messages);
        if (agent == null) {
            return requestBody;
        }
        if (agent.getAgentCode() != null && !agent.getAgentCode().isBlank()) {
            requestBody.put("agent_code", agent.getAgentCode());
        }
        List<String> memoryFiles = parseStringList(agent.getMemoryFiles());
        if (!memoryFiles.isEmpty()) {
            requestBody.put("memory_files", memoryFiles);
        }
        List<String> skillDirs = parseStringList(agent.getSkillDirs());
        if (!skillDirs.isEmpty()) {
            requestBody.put("skill_dirs", skillDirs);
        }
        List<String> toolAllowlist = parseStringList(agent.getToolAllowlist());
        if (!toolAllowlist.isEmpty()) {
            requestBody.put("tool_allowlist", toolAllowlist);
        }
        return requestBody;
    }

    private List<String> parseStringList(String value) {
        if (value == null || value.isBlank()) {
            return List.of();
        }
        String trimmed = value.trim();
        if (trimmed.startsWith("[") && trimmed.endsWith("]")) {
            try {
                List<String> parsed = objectMapper.readValue(trimmed, new TypeReference<List<String>>() {
                });
                return parsed.stream().filter(item -> item != null && !item.isBlank()).toList();
            } catch (Exception ignored) {
                // Fall through to delimiter parsing.
            }
        }
        List<String> items = new ArrayList<>();
        for (String item : trimmed.split("[,，;；\\n\\r\\t ]+")) {
            if (!item.isBlank()) {
                items.add(item.trim());
            }
        }
        return items;
    }

    /**
     * 解析 policy_config JSON：{"write":"allow|deny","workspace_root":"/path","execute":"deny"}。
     * 返回 allow_write(boolean) 与 workspace_root(string) 供编排使用。
     */
    private Map<String, Object> parsePolicyConfig(String value) {
        Map<String, Object> result = new java.util.LinkedHashMap<>();
        if (value == null || value.isBlank()) {
            return result;
        }
        try {
            JsonNode node = objectMapper.readTree(value);
            String write = node.path("write").asText("").trim().toLowerCase();
            if ("allow".equals(write)) {
                result.put("allow_write", true);
            }
            String wsRoot = node.path("workspace_root").asText("").trim();
            if (!wsRoot.isEmpty()) {
                result.put("workspace_root", wsRoot);
            }
        } catch (Exception ignored) {
            // 非 JSON 或格式不符时忽略，保持默认只读。
        }
        return result;
    }

    private void recordDeepAgentsEvent(String runId, String sessionId, Agent agent, JsonNode event) {
        String type = event.path("type").asText("agent_event");
        String title = event.path("title").asText(type);
        String content = event.path("content").asText("");
        Map<String, Object> payload = objectMapper.convertValue(event, new TypeReference<Map<String, Object>>() {
        });
        String eventType = switch (type) {
            case "tool_call" -> "tool_call_started";
            case "tool_result" -> "tool_call_completed";
            case "thinking" -> "agent_thinking";
            default -> type;
        };
        aiAgentRunService.recordEvent(runId, sessionId, agent, eventType, title, content, payload, "RUNNING");
    }

    private String invokeDeepAgents(String systemPrompt, List<Map<String, String>> messages) throws Exception {
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/agents/invoke";
        Map<String, Object> requestBody = Map.of(
                "system_prompt", systemPrompt,
                "messages", messages);
        String jsonBody = objectMapper.writeValueAsString(requestBody);

        HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        applyInternalApiAuth(conn);
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(900000);
        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        int responseCode = conn.getResponseCode();
        String responseBody;
        if (responseCode >= 200 && responseCode < 300) {
            responseBody = new String(conn.getInputStream().readAllBytes(), StandardCharsets.UTF_8);
        } else {
            responseBody = conn.getErrorStream() == null
                    ? ""
                    : new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
            throw new RuntimeException("DeepAgents 调用失败: " + responseCode + " - " + responseBody);
        }
        return extractAssistantContent(objectMapper.readTree(responseBody));
    }

    private void applyInternalApiAuth(HttpURLConnection conn) {
        if (internalApiAuthToken == null || internalApiAuthToken.isBlank()) {
            return;
        }
        conn.setRequestProperty(internalApiAuthHeader, internalApiAuthPrefix + internalApiAuthToken);
    }

    private String extractAssistantContent(JsonNode root) {
        JsonNode messages = root.path("output").path("messages");
        if (!messages.isArray() || messages.isEmpty()) {
            return root.path("output").toString();
        }
        for (int i = messages.size() - 1; i >= 0; i--) {
            JsonNode message = messages.get(i);
            String type = message.path("type").asText("");
            if (!"ai".equals(type) && !"assistant".equals(message.path("role").asText(""))) {
                continue;
            }
            JsonNode content = message.path("content");
            if (content.isTextual()) {
                return content.asText();
            }
            if (content.isArray()) {
                StringBuilder builder = new StringBuilder();
                for (JsonNode item : content) {
                    if (item.has("text")) {
                        builder.append(item.path("text").asText());
                    } else if (item.isTextual()) {
                        builder.append(item.asText());
                    }
                }
                return builder.toString();
            }
            return content.toString();
        }
        return "";
    }

    private List<Map<String, String>> normalizeConversationContext(List<Map<String, String>> rawContext) {
        if (rawContext == null || rawContext.isEmpty()) {
            return List.of();
        }
        List<Map<String, String>> context = new ArrayList<>();
        for (Map<String, String> item : rawContext) {
            if (item == null) {
                continue;
            }
            String role = normalizeRole(item.get("role"));
            String content = nullToEmpty(item.get("content"));
            if (role == null || content.isBlank()) {
                continue;
            }
            context.add(Map.of("role", role, "content", content));
        }
        return context;
    }

    private List<Map<String, String>> buildConversationContextFromHistory(String sessionId, String currentUserPrompt) {
        if (sessionId == null || sessionId.isBlank()) {
            return List.of();
        }
        List<Map<String, String>> context = new ArrayList<>();
        List<AiChatMessage> history = aiChatHistoryService.getSessionMessages(sessionId);
        if (history == null || history.isEmpty()) {
            return context;
        }
        String currentPrompt = nullToEmpty(currentUserPrompt);
        int lastIndex = history.size() - 1;
        for (int i = 0; i < history.size(); i++) {
            AiChatMessage message = history.get(i);
            String role = normalizeRole(message.getRole());
            String content = nullToEmpty(message.getContent());
            if (role == null || content.isBlank()) {
                continue;
            }
            if (i == lastIndex && "user".equals(role) && currentPrompt.equals(content)) {
                continue;
            }
            context.add(Map.of("role", role, "content", content));
        }
        return context;
    }

    private List<Map<String, String>> keepRecentConversationRounds(List<Map<String, String>> context) {
        if (context == null || context.size() <= KEEP_RECENT_ROUNDS * 2) {
            return context == null ? List.of() : context;
        }
        return context.subList(Math.max(0, context.size() - KEEP_RECENT_ROUNDS * 2), context.size());
    }

    private String resolveSystemPrompt(Agent agent, String fallback) {
        if (agent != null && agent.getSystemPrompt() != null && !agent.getSystemPrompt().isBlank()) {
            return agent.getSystemPrompt();
        }
        return fallback == null || fallback.isBlank() ? "You are a helpful assistant." : fallback;
    }

    private String normalizeRole(String role) {
        if (role == null) {
            return null;
        }
        String normalized = role.trim().toLowerCase();
        return "user".equals(normalized) || "assistant".equals(normalized) ? normalized : null;
    }

    private String nullToEmpty(String value) {
        return value == null ? "" : value;
    }

}
