package com.example.urgs_api.metadata.review.service;

import com.example.urgs_api.ai.client.AiClient;
import com.example.urgs_api.ai.service.AiApiConfigService;
import com.example.urgs_api.metadata.review.dto.LineageReviewAIVerdict;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@Service
public class LineageReviewAiService {

    private static final String SYSTEM_PROMPT = """
            你是一名 SQL 血缘复核助手。
            你的任务不是发明真值血缘，而是根据规则命中、局部图谱和 SQL 片段判断当前疑点是否成立。
            请严格输出 JSON，不要输出 Markdown，不要输出额外解释。
            JSON 结构如下：
            {
              "issueType": "MISSING_SOURCE|OVER_CONNECTED|RELATION_TYPE_MISMATCH|SPARSE_TABLE_LINEAGE|AMBIGUOUS_MAPPING|NEEDS_MANUAL_REVIEW",
              "severity": "HIGH|MEDIUM|LOW",
              "confidence": 0.0,
              "verdict": "CONFIRMED|REJECTED|NEEDS_REVIEW",
              "reason": "简要理由",
              "suggestedSources": ["schema.table.column"],
              "evidenceRefs": ["证据1", "证据2"]
            }
            如果证据不足，请返回 NEEDS_REVIEW，不要臆断。
            """;

    private final AiClient aiClient;
    private final AiApiConfigService aiApiConfigService;
    private final ObjectMapper objectMapper;

    public LineageReviewAiService(AiClient aiClient,
            AiApiConfigService aiApiConfigService,
            ObjectMapper objectMapper) {
        this.aiClient = aiClient;
        this.aiApiConfigService = aiApiConfigService;
        this.objectMapper = objectMapper;
    }

    public LineageReviewAIVerdict review(LineageReviewIssue draftIssue, Map<String, Object> evidence) {
        try {
            String response = aiClient.chat(SYSTEM_PROMPT, buildPrompt(draftIssue, evidence));
            return parseResponse(response, draftIssue);
        } catch (Exception ex) {
            return fallbackVerdict(draftIssue, "AI 调用失败，已降级为规则结果: " + ex.getMessage());
        }
    }

    public String resolveModelName() {
        var config = aiApiConfigService.getDefaultConfig();
        if (config == null) {
            return "RULE_ONLY";
        }
        return config.getProvider() + "/" + config.getModel();
    }

    private String buildPrompt(LineageReviewIssue draftIssue, Map<String, Object> evidence) {
        return """
                请根据以下证据复核 SQL 血缘疑点。

                [目标对象]
                表: %s
                字段: %s
                疑点类型: %s
                严重级别: %s
                规则命中: %s

                [证据包]
                %s
                """.formatted(
                draftIssue.getTableName(),
                draftIssue.getColumnName(),
                draftIssue.getIssueType(),
                draftIssue.getSeverity(),
                draftIssue.getRuleHits(),
                toJson(evidence));
    }

    private LineageReviewAIVerdict parseResponse(String response, LineageReviewIssue draftIssue) {
        try {
            String json = extractJson(response);
            JsonNode node = objectMapper.readTree(json);
            LineageReviewAIVerdict verdict = new LineageReviewAIVerdict();
            verdict.setIssueType(readText(node, "issueType", draftIssue.getIssueType()));
            verdict.setSeverity(readText(node, "severity", draftIssue.getSeverity()));
            verdict.setConfidence(readDecimal(node, "confidence", BigDecimal.valueOf(0.60)));
            verdict.setVerdict(readText(node, "verdict", "NEEDS_REVIEW"));
            verdict.setReason(readText(node, "reason", "AI 已完成复核，但未返回充分理由"));
            verdict.setSuggestedSources(readArray(node.get("suggestedSources")));
            verdict.setEvidenceRefs(readArray(node.get("evidenceRefs")));
            return verdict;
        } catch (Exception ex) {
            return fallbackVerdict(draftIssue, "AI 返回无法解析，已降级为规则结果");
        }
    }

    private LineageReviewAIVerdict fallbackVerdict(LineageReviewIssue draftIssue, String reason) {
        LineageReviewAIVerdict verdict = new LineageReviewAIVerdict();
        verdict.setIssueType(draftIssue.getIssueType());
        verdict.setSeverity(draftIssue.getSeverity());
        verdict.setConfidence(BigDecimal.valueOf(0.55));
        verdict.setVerdict("NEEDS_REVIEW");
        verdict.setReason(reason);
        verdict.setSuggestedSources(new ArrayList<>());
        verdict.setEvidenceRefs(draftIssue.getEvidenceRefs() == null ? new ArrayList<>() : draftIssue.getEvidenceRefs());
        return verdict;
    }

    private String readText(JsonNode node, String field, String fallback) {
        return node.hasNonNull(field) ? node.get(field).asText() : fallback;
    }

    private BigDecimal readDecimal(JsonNode node, String field, BigDecimal fallback) {
        if (!node.hasNonNull(field)) {
            return fallback;
        }
        return BigDecimal.valueOf(node.get(field).asDouble()).setScale(4, RoundingMode.HALF_UP);
    }

    private List<String> readArray(JsonNode node) {
        List<String> values = new ArrayList<>();
        if (node == null || !node.isArray()) {
            return values;
        }
        for (JsonNode item : node) {
            values.add(item.asText());
        }
        return values;
    }

    private String extractJson(String raw) {
        int start = raw.indexOf('{');
        int end = raw.lastIndexOf('}');
        if (start >= 0 && end > start) {
            return raw.substring(start, end + 1);
        }
        return raw;
    }

    private String toJson(Map<String, Object> evidence) {
        try {
            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(evidence);
        } catch (Exception ex) {
            return String.valueOf(evidence);
        }
    }
}
