package com.example.urgs_api.ai.client;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Map;

/**
 * 调用 urgs-deepagents 的编排流式接口 /v1/orchestrator/stream。
 * 仅负责 HTTP 与 SSE 解析，编排逻辑全部在 DeepAgents 侧。
 */
@Component
public class DeepAgentsOrchestratorClient {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final String deepAgentsBaseUrl;

    public DeepAgentsOrchestratorClient(
            @Value("${urgs.deepagents.base-url:http://127.0.0.1:8003}") String deepAgentsBaseUrl) {
        this.deepAgentsBaseUrl = deepAgentsBaseUrl;
    }

    public interface EventListener {
        void onEvent(String eventName, JsonNode data) throws Exception;
    }

    public void stream(Map<String, Object> requestBody, EventListener listener) throws Exception {
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/orchestrator/stream";
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
            String errorBody = conn.getErrorStream() == null
                    ? ""
                    : new String(conn.getErrorStream().readAllBytes(), StandardCharsets.UTF_8);
            throw new RuntimeException("DeepAgents 编排调用失败: " + responseCode + " - " + errorBody);
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
                JsonNode node = objectMapper.readTree(data);
                listener.onEvent(currentEvent, node);
            }
        }
    }
}
