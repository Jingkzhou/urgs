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
              "issueType": "MISSING_SOURCE|WRONG_SOURCE|WRONG_TARGET|WRONG_RELATION_TYPE|OVER_CONNECTED|RELATION_TYPE_MISMATCH|SPARSE_TABLE_LINEAGE|AMBIGUOUS_MAPPING|UNCERTAIN_MAPPING|NEEDS_MANUAL_REVIEW",
              "severity": "HIGH|MEDIUM|LOW",
              "confidence": 0.0,
              "verdict": "CONFIRMED|REJECTED|NEEDS_REVIEW",
              "reason": "简要理由",
              "suggestedSources": ["schema.table.column"],
              "evidenceRefs": ["证据1", "证据2"]
            }
            如果证据不足，请返回 NEEDS_REVIEW，不要臆断。
            """;

    private static final String SQL_AUDIT_SYSTEM_PROMPT = """
            你是一名 SQL 血缘二次校验助手。
            你的任务是对照原始 SQL 和程序抽取出的血缘关系，判断程序结果是否有遗漏或错误。
            必须只基于 SQL 文本、程序关系列表和给定证据判断；不要补充无法从 SQL 推断的血缘。
            重点检查：
            1. 是否漏掉 SELECT、JOIN、WHERE、CASE、GROUP BY、ORDER BY、函数参数中的来源字段或来源表；
            2. 是否把不相关字段/表错误连接到目标字段/表；
            3. 目标字段是否对错位；
            4. 关系类型是否错误，例如数据派生、过滤、关联、分组、排序、条件。
            请严格输出 JSON，不要输出 Markdown，不要输出额外解释。
            JSON 结构如下：
            {
              "issues": [
                {
                  "issueType": "MISSING_SOURCE|WRONG_SOURCE|WRONG_TARGET|WRONG_RELATION_TYPE|UNCERTAIN_MAPPING|NEEDS_MANUAL_REVIEW|NO_ISSUE",
                  "targetTable": "schema.table",
                  "targetColumn": "column_name 或 null",
                  "severity": "HIGH|MEDIUM|LOW",
                  "confidence": 0.0,
                  "verdict": "CONFIRMED|REJECTED|NEEDS_REVIEW",
                  "reason": "简要说明",
                  "suggestedSources": ["schema.table.column"],
                  "evidenceRefs": ["SQL片段或程序关系证据"]
                }
              ]
            }
            如果程序结果正确，请只返回一个 NO_ISSUE 且 verdict 为 REJECTED。
            每一条疑点必须明确 targetTable；字段级疑点必须明确 targetColumn，表级疑点 targetColumn 可为 null。
            CONFIRMED 或 NEEDS_REVIEW 必须提供 evidenceRefs，证据必须来自 sqlSnippet 的原文片段或 programRelations 中的具体关系。
            如果无法给出具体证据，不要列为疑点；常量、字符串字面量、数字字面量、存储过程参数或变量不是缺失的表字段来源。
            如果证据不足，请不要输出该疑点，或返回 NO_ISSUE 且 verdict 为 REJECTED。
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

    public List<LineageReviewAIVerdict> auditSqlLineage(Map<String, Object> evidence) {
        try {
            String response = aiClient.chat(SQL_AUDIT_SYSTEM_PROMPT, buildSqlAuditPrompt(evidence));
            return parseIssueList(response);
        } catch (Exception ex) {
            LineageReviewAIVerdict verdict = new LineageReviewAIVerdict();
            verdict.setIssueType("NEEDS_MANUAL_REVIEW");
            verdict.setSeverity("MEDIUM");
            verdict.setConfidence(BigDecimal.valueOf(0.55));
            verdict.setVerdict("NEEDS_REVIEW");
            verdict.setReason("AI 二次校验调用失败: " + ex.getMessage());
            verdict.setSuggestedSources(new ArrayList<>());
            verdict.setEvidenceRefs(new ArrayList<>());
            return List.of(verdict);
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

    private String buildSqlAuditPrompt(Map<String, Object> evidence) {
        return """
                请对照以下 SQL 和程序抽取出的血缘关系，判断是否存在遗漏或错误。

                [证据包]
                %s
                """.formatted(toJson(evidence));
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

    private List<LineageReviewAIVerdict> parseIssueList(String response) {
        List<LineageReviewAIVerdict> results = new ArrayList<>();
        try {
            String json = extractJson(response);
            JsonNode root = objectMapper.readTree(json);
            JsonNode issues = root.has("issues") ? root.get("issues") : root;
            if (!issues.isArray()) {
                return results;
            }
            for (JsonNode node : issues) {
                LineageReviewAIVerdict verdict = new LineageReviewAIVerdict();
                verdict.setIssueType(readText(node, "issueType", "NEEDS_MANUAL_REVIEW"));
                verdict.setTargetTable(readText(node, "targetTable", null));
                verdict.setTargetColumn(readText(node, "targetColumn", null));
                verdict.setSeverity(readText(node, "severity", "MEDIUM"));
                verdict.setConfidence(readDecimal(node, "confidence", BigDecimal.valueOf(0.60)));
                verdict.setVerdict(readText(node, "verdict", "NEEDS_REVIEW"));
                verdict.setReason(readText(node, "reason", "AI 二次校验未返回充分理由"));
                verdict.setSuggestedSources(readArray(node.get("suggestedSources")));
                verdict.setEvidenceRefs(readArray(node.get("evidenceRefs")));
                results.add(verdict);
            }
        } catch (Exception ex) {
            LineageReviewAIVerdict verdict = new LineageReviewAIVerdict();
            verdict.setIssueType("NEEDS_MANUAL_REVIEW");
            verdict.setSeverity("MEDIUM");
            verdict.setConfidence(BigDecimal.valueOf(0.55));
            verdict.setVerdict("NEEDS_REVIEW");
            verdict.setReason("AI 二次校验返回无法解析，需人工复核");
            verdict.setSuggestedSources(new ArrayList<>());
            verdict.setEvidenceRefs(new ArrayList<>());
            results.add(verdict);
        }
        return results;
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
