package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.Agent;
import com.example.urgs_api.ai.entity.AiApiConfig;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

@Service
public class AiTokenBudgetService {

    public static final int FALLBACK_CONTEXT_WINDOW = 30000;

    private static final int MESSAGE_OVERHEAD_TOKENS = 4;
    private static final ObjectMapper objectMapper = new ObjectMapper();

    private final AiApiConfigService aiApiConfigService;

    public AiTokenBudgetService(AiApiConfigService aiApiConfigService) {
        this.aiApiConfigService = aiApiConfigService;
    }

    public int resolveContextWindow(Agent agent) {
        Integer agentWindow = resolveAgentContextWindow(agent);
        if (agentWindow != null && agentWindow > 0) {
            return agentWindow;
        }

        AiApiConfig defaultConfig = aiApiConfigService.getDefaultConfig();
        Integer defaultMaxTokens = defaultConfig == null ? null : defaultConfig.getMaxTokens();
        return defaultMaxTokens == null || defaultMaxTokens <= 0 ? FALLBACK_CONTEXT_WINDOW : defaultMaxTokens;
    }

    public int estimateMessages(List<Map<String, String>> messages) {
        if (messages == null || messages.isEmpty()) {
            return 0;
        }
        int total = 0;
        for (Map<String, String> message : messages) {
            if (message == null) {
                continue;
            }
            total += MESSAGE_OVERHEAD_TOKENS;
            total += estimateText(message.get("role"));
            total += estimateText(message.get("content"));
        }
        return total;
    }

    public int estimateText(String text) {
        if (text == null || text.isBlank()) {
            return 0;
        }

        int cjkChars = 0;
        int nonCjkChars = 0;
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            if (isCjk(ch)) {
                cjkChars++;
            } else if (!Character.isWhitespace(ch)) {
                nonCjkChars++;
            }
        }
        return cjkChars + (int) Math.ceil(nonCjkChars / 4.0);
    }

    private Integer resolveAgentContextWindow(Agent agent) {
        if (agent == null || agent.getModelConfig() == null || agent.getModelConfig().isBlank()) {
            return null;
        }
        try {
            JsonNode node = objectMapper.readTree(agent.getModelConfig());
            return firstPositiveInt(node, "contextWindow", "context_window", "maxTokens", "max_tokens");
        } catch (Exception e) {
            return null;
        }
    }

    private Integer firstPositiveInt(JsonNode node, String... fieldNames) {
        if (node == null || !node.isObject()) {
            return null;
        }
        for (String fieldName : fieldNames) {
            JsonNode value = node.get(fieldName);
            if (value != null && value.canConvertToInt() && value.asInt() > 0) {
                return value.asInt();
            }
        }
        return null;
    }

    private boolean isCjk(char ch) {
        Character.UnicodeBlock block = Character.UnicodeBlock.of(ch);
        return block == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS
                || block == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_A
                || block == Character.UnicodeBlock.CJK_UNIFIED_IDEOGRAPHS_EXTENSION_B
                || block == Character.UnicodeBlock.CJK_COMPATIBILITY_IDEOGRAPHS
                || block == Character.UnicodeBlock.CJK_SYMBOLS_AND_PUNCTUATION
                || block == Character.UnicodeBlock.HALFWIDTH_AND_FULLWIDTH_FORMS;
    }
}
