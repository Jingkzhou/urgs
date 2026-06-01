package com.example.urgs_api.ai.service.agent;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.entity.AiChatSession;
import com.example.urgs_api.ai.service.AiChatHistoryService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

@Component
public class DifyBuildModeHandler {

    private static final Logger log = LoggerFactory.getLogger(DifyBuildModeHandler.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private AiChatHistoryService aiChatHistoryService;

    public boolean supports(Agent agent) {
        return agent != null
                && ("DIFY".equalsIgnoreCase(agent.getBuildMode())
                        || (agent.getDifyApiKey() != null && !agent.getDifyApiKey().isBlank()));
    }

    public void stream(String sessionId, AiChatSession sessionInfo, Agent agent, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer) throws Exception {
        String difyApiKey = agent.getDifyApiKey();
        String difyApiBase = agent.getDifyApiBase() != null && !agent.getDifyApiBase().isBlank()
                ? agent.getDifyApiBase()
                : "https://api.dify.ai/v1";

        if (difyApiKey == null || difyApiKey.isBlank()) {
            throw new RuntimeException("Dify API Key 未配置");
        }

        log.info("Delegating stream request to Dify API for session {}", sessionId);
        boolean isWorkflowApp = false;
        HttpURLConnection conn = null;

        for (int attempt = 0; attempt < 2; attempt++) {
            String difyEndpoint = difyApiBase;
            if (!difyEndpoint.endsWith("/")) {
                difyEndpoint += "/";
            }
            difyEndpoint += isWorkflowApp ? "workflows/run" : "chat-messages";

            String query = messages.isEmpty() ? "" : messages.get(messages.size() - 1).getOrDefault("content", "");
            String difyConversationId = sessionInfo != null ? sessionInfo.getDifyConversationId() : null;

            Map<String, Object> difyReq = buildDifyRequest(sessionInfo, isWorkflowApp, query, difyConversationId);
            String jsonBody = objectMapper.writeValueAsString(difyReq);

            conn = (HttpURLConnection) URI.create(difyEndpoint).toURL().openConnection();
            conn.setRequestMethod("POST");
            conn.setRequestProperty(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
            conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + difyApiKey);
            conn.setRequestProperty(HttpHeaders.ACCEPT, "text/event-stream");
            conn.setDoOutput(true);
            conn.setConnectTimeout(30000);
            conn.setReadTimeout(120000);

            try (OutputStream os = conn.getOutputStream()) {
                os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
            }

            int responseCode = conn.getResponseCode();
            if (responseCode == 200) {
                break;
            }

            String errorBody = new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
            if (!isWorkflowApp && responseCode == 400 && errorBody.contains("not_chat_app")) {
                log.info("Dify app is not a chat app, retrying as workflow app...");
                isWorkflowApp = true;
                continue;
            }
            throw new RuntimeException("Dify API 调用失败: " + responseCode + " - " + errorBody);
        }

        if (conn == null) {
            throw new RuntimeException("Dify API 连接创建失败");
        }
        readDifyStream(conn, sessionInfo, isWorkflowApp, chunkConsumer);
    }

    private Map<String, Object> buildDifyRequest(AiChatSession sessionInfo, boolean isWorkflowApp, String query,
            String difyConversationId) {
        Map<String, Object> difyReq = new java.util.HashMap<>();
        difyReq.put("response_mode", "streaming");
        difyReq.put("user", sessionInfo != null && sessionInfo.getUserId() != null ? sessionInfo.getUserId() : "system");

        if (isWorkflowApp) {
            Map<String, Object> inputs = new java.util.HashMap<>();
            inputs.put("query", query);
            inputs.put("user_question", query);
            inputs.put("input", query);
            difyReq.put("inputs", inputs);
        } else {
            difyReq.put("inputs", new java.util.HashMap<>());
            difyReq.put("query", query);
            if (difyConversationId != null && !difyConversationId.isBlank()) {
                difyReq.put("conversation_id", difyConversationId);
            }
        }
        return difyReq;
    }

    private void readDifyStream(HttpURLConnection conn, AiChatSession sessionInfo, boolean isWorkflowApp,
            Consumer<String> chunkConsumer) throws Exception {
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            boolean isFirstDetailedMessage = true;
            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("data: ")) {
                    continue;
                }
                String data = line.substring(6).trim();
                if (data.isEmpty()) {
                    continue;
                }
                isFirstDetailedMessage = handleDifyEvent(data, sessionInfo, isWorkflowApp, isFirstDetailedMessage,
                        chunkConsumer);
            }
        }
    }

    private boolean handleDifyEvent(String data, AiChatSession sessionInfo, boolean isWorkflowApp,
            boolean isFirstDetailedMessage, Consumer<String> chunkConsumer) {
        try {
            JsonNode node = objectMapper.readTree(data);
            String event = node.has("event") ? node.get("event").asText() : "";

            if (!isWorkflowApp) {
                if ("message".equals(event) || "agent_message".equals(event)) {
                    if (node.has("answer")) {
                        String answer = node.get("answer").asText();
                        if (answer != null && !answer.isEmpty()) {
                            chunkConsumer.accept(answer);
                        }
                    }
                } else if ("message_end".equals(event)) {
                    return isFirstDetailedMessage;
                }

                if (isFirstDetailedMessage && node.has("conversation_id")) {
                    String newConvId = node.get("conversation_id").asText();
                    if (newConvId != null && !newConvId.isBlank() && sessionInfo != null
                            && (sessionInfo.getDifyConversationId() == null
                                    || sessionInfo.getDifyConversationId().isBlank())) {
                        sessionInfo.setDifyConversationId(newConvId);
                        aiChatHistoryService.updateSession(sessionInfo);
                        log.info("Saved new Dify Conversation ID: {}", newConvId);
                        return false;
                    }
                }
            } else if ("text_chunk".equals(event) || "node_chunk".equals(event)) {
                if (node.has("data") && node.get("data").has("text")) {
                    String text = node.get("data").get("text").asText();
                    if (text != null && !text.isEmpty()) {
                        chunkConsumer.accept(text);
                    }
                }
            }
        } catch (Exception e) {
            log.warn("Failed to parse Dify SSE data: {} | Exception: {}", data, e.getMessage());
        }
        return isFirstDetailedMessage;
    }
}
