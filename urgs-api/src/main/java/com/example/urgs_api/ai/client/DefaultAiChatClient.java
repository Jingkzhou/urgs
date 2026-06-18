package com.example.urgs_api.ai.client;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.AiApiConfigService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.function.Consumer;

/**
 * OpenAI-compatible default AI client used by legacy/general chat paths.
 *
 * DeepAgents orchestration remains the owner for DEEPAGENTS agents; this client keeps
 * generic AI features working when the DeepAgents sidecar is not deployed.
 */
@Component
public class DefaultAiChatClient {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final AiApiConfigService aiApiConfigService;

    public DefaultAiChatClient(AiApiConfigService aiApiConfigService) {
        this.aiApiConfigService = aiApiConfigService;
    }

    public String invoke(String systemPrompt, List<Map<String, String>> messages) throws Exception {
        StringBuilder response = new StringBuilder();
        streamInternal(systemPrompt, messages, response::append);
        return response.toString();
    }

    public void stream(String systemPrompt, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer, Runnable onComplete, Consumer<Exception> onError) {
        try {
            streamInternal(systemPrompt, messages, chunkConsumer);
            onComplete.run();
        } catch (Exception e) {
            onError.accept(e);
        }
    }

    private void streamInternal(String systemPrompt, List<Map<String, String>> messages,
            Consumer<String> chunkConsumer) throws Exception {
        AiApiConfig config = aiApiConfigService.getDefaultConfig();
        if (config == null) {
            throw new IllegalStateException("未配置默认 AI API");
        }

        HttpURLConnection conn = (HttpURLConnection) URI.create(resolveChatCompletionsEndpoint(config))
                .toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setRequestProperty("Accept", "text/event-stream");
        if (config.getApiKey() != null && !config.getApiKey().isBlank()) {
            conn.setRequestProperty("Authorization", "Bearer " + config.getApiKey());
        }
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(900000);

        String jsonBody = objectMapper.writeValueAsString(buildRequestBody(systemPrompt, messages, config));
        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        int responseCode = conn.getResponseCode();
        if (responseCode < 200 || responseCode >= 300) {
            throw new RuntimeException("默认 AI API 调用失败: HTTP " + responseCode + " - "
                    + sanitize(readBody(conn.getErrorStream())));
        }

        readResponse(conn, chunkConsumer);
    }

    private Map<String, Object> buildRequestBody(String systemPrompt, List<Map<String, String>> messages,
            AiApiConfig config) {
        Map<String, Object> body = new LinkedHashMap<>();
        body.put("model", resolveModel(config));
        body.put("messages", buildMessages(systemPrompt, messages));
        body.put("stream", true);
        if (config.getMaxTokens() != null && config.getMaxTokens() > 0) {
            body.put("max_tokens", config.getMaxTokens());
        }
        if (config.getTemperature() != null) {
            body.put("temperature", config.getTemperature());
        }
        return body;
    }

    private List<Map<String, String>> buildMessages(String systemPrompt, List<Map<String, String>> messages) {
        List<Map<String, String>> normalized = new ArrayList<>();
        if (messages != null) {
            for (Map<String, String> message : messages) {
                if (message == null) {
                    continue;
                }
                String role = message.get("role");
                String content = message.get("content");
                if (role != null && content != null && !content.isBlank()) {
                    normalized.add(Map.of("role", role, "content", content));
                }
            }
        }
        boolean hasSystem = !normalized.isEmpty() && "system".equals(normalized.get(0).get("role"));
        if (!hasSystem && systemPrompt != null && !systemPrompt.isBlank()) {
            normalized.add(0, Map.of("role", "system", "content", systemPrompt));
        }
        return normalized;
    }

    private String resolveChatCompletionsEndpoint(AiApiConfig config) {
        String endpoint = config.getEndpoint();
        if (endpoint == null || endpoint.isBlank()) {
            throw new IllegalStateException("默认 AI API endpoint 不能为空");
        }
        String normalized = endpoint.trim().replaceAll("/+$", "");
        if (normalized.endsWith("/chat/completions")) {
            return normalized;
        }
        return normalized + "/chat/completions";
    }

    private String resolveModel(AiApiConfig config) {
        String model = config.getModel();
        return model == null || model.isBlank() ? "gpt-3.5-turbo" : model;
    }

    private void readResponse(HttpURLConnection conn, Consumer<String> chunkConsumer) throws Exception {
        StringBuilder plainBody = new StringBuilder();
        boolean emitted = false;
        try (BufferedReader reader = new BufferedReader(
                new InputStreamReader(conn.getInputStream(), StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                if (!line.startsWith("data:")) {
                    if (!line.isBlank() && !line.startsWith("event:")) {
                        plainBody.append(line);
                    }
                    continue;
                }
                String data = line.substring(5).trim();
                if (data.isBlank() || "[DONE]".equals(data)) {
                    continue;
                }
                String content = extractAssistantContent(objectMapper.readTree(data));
                if (!content.isEmpty()) {
                    emitted = true;
                    chunkConsumer.accept(content);
                }
            }
        }
        if (!emitted && !plainBody.isEmpty()) {
            String content = extractAssistantContent(objectMapper.readTree(plainBody.toString()));
            if (!content.isEmpty()) {
                chunkConsumer.accept(content);
            }
        }
    }

    private String extractAssistantContent(JsonNode root) {
        JsonNode choices = root.path("choices");
        if (!choices.isArray() || choices.isEmpty()) {
            return "";
        }
        JsonNode choice = choices.get(0);
        JsonNode delta = choice.path("delta").path("content");
        if (delta.isTextual()) {
            return delta.asText();
        }
        JsonNode message = choice.path("message").path("content");
        return message.isTextual() ? message.asText() : "";
    }

    private String readBody(InputStream stream) throws Exception {
        if (stream == null) {
            return "";
        }
        return new String(stream.readAllBytes(), StandardCharsets.UTF_8);
    }

    private String sanitize(String value) {
        if (value == null || value.isBlank()) {
            return "";
        }
        String text = value
                .replaceAll("(?i)(bearer\\s+)[a-z0-9._\\-+/=]+", "$1[REDACTED]")
                .replaceAll("(?i)sk-[a-z0-9_\\-]{8,}", "[REDACTED]")
                .replaceAll("(?i)((?:api[_-]?key|token|secret|password)\\s*[=:]\\s*)[^\\s,;]+",
                        "$1[REDACTED]")
                .replaceAll(
                        "https?://(127\\.0\\.0\\.1|localhost|10\\.\\d+\\.\\d+\\.\\d+|172\\.(1[6-9]|2\\d|3[01])\\.\\d+\\.\\d+|192\\.168\\.\\d+\\.\\d+)(:\\d+)?\\S*",
                        "[INTERNAL_URL]");
        return text.length() > 1000 ? text.substring(0, 1000) : text;
    }
}
