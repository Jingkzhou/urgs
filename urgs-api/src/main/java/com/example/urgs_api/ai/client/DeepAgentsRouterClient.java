package com.example.urgs_api.ai.client;

import com.example.urgs_api.ai.entity.Agent;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class DeepAgentsRouterClient {

    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final String deepAgentsBaseUrl;

    public DeepAgentsRouterClient(
            @Value("${urgs.deepagents.base-url:http://127.0.0.1:8003}") String deepAgentsBaseUrl) {
        this.deepAgentsBaseUrl = deepAgentsBaseUrl;
    }

    public RouteResult route(String message, List<Agent> agents) throws Exception {
        if (agents == null || agents.isEmpty()) {
            throw new IllegalStateException("没有可用于路由的启用 Agent");
        }
        String endpoint = deepAgentsBaseUrl.replaceAll("/+$", "") + "/v1/router/route";
        Map<String, Object> requestBody = new LinkedHashMap<>();
        requestBody.put("message", message);
        requestBody.put("agents", serializeAgents(agents));
        String jsonBody = objectMapper.writeValueAsString(requestBody);

        HttpURLConnection conn = (HttpURLConnection) URI.create(endpoint).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty("Content-Type", "application/json");
        conn.setDoOutput(true);
        conn.setConnectTimeout(10000);
        conn.setReadTimeout(120000);
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
            throw new RuntimeException("DeepAgents Router 调用失败: " + responseCode + " - " + responseBody);
        }

        JsonNode root = objectMapper.readTree(responseBody);
        String agentCode = root.path("agent_code").asText("");
        if (agentCode.isBlank()) {
            throw new RuntimeException("DeepAgents Router 未返回 agent_code");
        }
        return new RouteResult(
                agentCode,
                root.path("confidence").asDouble(0.0),
                root.path("reason").asText(""),
                root.path("task_type").asText(""),
                root.path("requires_collaboration").asBoolean(false),
                root.path("collaboration_plan").asText(""));
    }

    private List<Map<String, Object>> serializeAgents(List<Agent> agents) {
        List<Map<String, Object>> items = new ArrayList<>();
        for (Agent agent : agents) {
            Map<String, Object> item = new LinkedHashMap<>();
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

    public record RouteResult(String agentCode, double confidence, String reason, String taskType,
            boolean requiresCollaboration, String collaborationPlan) {
    }
}
