package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.ai.entity.AiChatMessage;
import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.service.AiChatHistoryService;
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
    private static final int MAX_CONTEXT_TOKENS = 30000;
    private static final int KEEP_RECENT_ROUNDS = 3;

    private final AiChatHistoryService aiChatHistoryService;
    private final String deepAgentsBaseUrl;

    public DeepAgentsBuildModeHandler(
            AiChatHistoryService aiChatHistoryService,
            @Value("${urgs.deepagents.base-url:http://127.0.0.1:8003}") String deepAgentsBaseUrl) {
        this.aiChatHistoryService = aiChatHistoryService;
        this.deepAgentsBaseUrl = deepAgentsBaseUrl;
    }

    public boolean supports(Agent agent) {
        return agent != null && "DEEPAGENTS".equalsIgnoreCase(agent.getBuildMode());
    }

    public void streamWithPersistence(String sessionId, Agent agent, String systemPrompt, String userPrompt,
            List<Map<String, String>> conversationContext, SseEmitter emitter) {
        executor.submit(() -> {
            String response = "";
            try {
                emitter.send(SseEmitter.event().name("status").data("deepagents_running"));

                List<Map<String, String>> messages = buildMessages(sessionId, userPrompt, conversationContext);
                long used = estimateTokens(messages.stream()
                        .map(item -> item.getOrDefault("content", ""))
                        .reduce("", String::concat));
                emitter.send(SseEmitter.event().name("metrics")
                        .data(objectMapper.writeValueAsString(Map.of("used", used, "limit", MAX_CONTEXT_TOKENS))));

                StringBuilder responseBuilder = new StringBuilder();
                streamDeepAgents(resolveSystemPrompt(agent, systemPrompt), messages,
                        chunk -> {
                            responseBuilder.append(chunk);
                            try {
                                emitter.send(SseEmitter.event()
                                        .data(objectMapper.writeValueAsString(Map.of("content", chunk))));
                            } catch (Exception e) {
                                throw new RuntimeException("SSE connection broken", e);
                            }
                        },
                        event -> {
                            try {
                                emitter.send(SseEmitter.event().name("agent")
                                        .data(objectMapper.writeValueAsString(event)));
                            } catch (Exception e) {
                                throw new RuntimeException("SSE connection broken", e);
                            }
                        });
                response = responseBuilder.toString();
                aiChatHistoryService.saveMessage(sessionId, "assistant", response);
                emitter.send(SseEmitter.event().data("[DONE]"));
                emitter.complete();
            } catch (Exception e) {
                log.error("DeepAgents execution failed for session {}", sessionId, e);
                try {
                    if (!response.isBlank()) {
                        aiChatHistoryService.saveMessage(sessionId, "assistant", response);
                    }
                    emitter.send(SseEmitter.event()
                            .data(objectMapper.writeValueAsString(Map.of("error", e.getMessage()))));
                    emitter.complete();
                } catch (Exception ex) {
                    log.warn("Failed to send DeepAgents error event", ex);
                }
            }
        });
    }

    public String invokeDefault(String systemPrompt, List<Map<String, String>> messages) throws Exception {
        StringBuilder response = new StringBuilder();
        streamDeepAgents(systemPrompt, normalizeConversationContext(messages), response::append, event -> {
        });
        return response.toString();
    }

    public void streamDefault(String systemPrompt, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer, Runnable onComplete, Consumer<Exception> onError) {
        try {
            streamDeepAgents(systemPrompt, normalizeConversationContext(messages), chunkConsumer, event -> {
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

    private void streamDeepAgents(String systemPrompt, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer, Consumer<JsonNode> eventConsumer) throws Exception {
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/agents/stream";
        Map<String, Object> requestBody = Map.of(
                "system_prompt", systemPrompt,
                "messages", messages);
        String jsonBody = objectMapper.writeValueAsString(requestBody);

        HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "text/event-stream");
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

    private String invokeDeepAgents(String systemPrompt, List<Map<String, String>> messages) throws Exception {
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/agents/invoke";
        Map<String, Object> requestBody = Map.of(
                "system_prompt", systemPrompt,
                "messages", messages);
        String jsonBody = objectMapper.writeValueAsString(requestBody);

        HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
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

    private long estimateTokens(String text) {
        return text == null || text.isEmpty() ? 0 : text.length() / 4;
    }
}
