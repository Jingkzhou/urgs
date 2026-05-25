package com.example.urgs_api.metadata.review.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.ai.client.AiClient;
import com.example.urgs_api.ai.service.AiApiConfigService;
import com.example.urgs_api.metadata.review.dto.LineageReviewAIVerdict;
import com.example.urgs_api.metadata.review.entity.LineageReviewIssue;
import com.example.urgs_api.metadata.review.entity.LineageReviewMemory;
import com.example.urgs_api.metadata.review.mapper.LineageReviewMemoryMapper;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class LineageReviewAiService {

    private static final String RELATION_TYPE_GUIDE = """
            DERIVES_TO: 直接数据派生。源字段的值直接组成、转换、计算或复制到目标字段，适用于 SELECT 表达式、函数结果、算术计算等值级来源。
            CASE_WHEN: 条件分支依赖。源字段出现在 CASE/IF 的 WHEN 条件中，用于决定目标字段取哪个分支；它是条件/控制依赖，不等同于目标字段值的直接来源。
            FILTERS: 过滤依赖。源字段出现在 WHERE/HAVING 等过滤条件中，只影响结果集是否保留。
            JOINS: 关联依赖。源字段出现在 JOIN/ON 条件中，只影响表之间匹配关系。
            GROUPS: 分组依赖。源字段出现在 GROUP BY 中，只影响聚合粒度。
            ORDERS: 排序依赖。源字段出现在 ORDER BY 中，只影响排序或窗口顺序。
            CALLS: 调用依赖。源对象通过函数、过程或动态调用参与计算。
            REFERENCES: 引用依赖。源对象被 SQL 引用但不一定形成字段值派生。
            判定约束: NO_DIRECT_DERIVATION 只适用于目标字段本应存在值级来源但程序没有 DERIVES_TO 的场景；不适用于 CASE_WHEN、FILTERS、JOINS、GROUPS、ORDERS 这类条件或影响关系。
            判定约束: 如果目标字段由 CASE WHEN 的 THEN/ELSE 常量、字面量或分类值生成，而源字段只出现在 WHEN 条件中，CASE_WHEN 已是正确血缘，不应判定为缺少直接派生。
            """;

    private static final int MEMORY_LIMIT = 20;
    private static final int MEMORY_PROMPT_CHAR_LIMIT = 8000;
    private static final int SUMMARY_MEMORY_CHAR_LIMIT = 8000;
    private static final int SUMMARY_PROMPT_SAMPLE_CHAR_LIMIT = 12000;

    private static final String SYSTEM_PROMPT = """
            你是一名 SQL 血缘复核助手。
            你的任务不是发明真值血缘，而是根据规则命中、局部图谱和 SQL 片段判断当前疑点是否成立。
            复核时必须严格按关系类型定义判断，不得把条件血缘误判成直接派生缺失。
            如果提供了历史走查记忆，必须优先参考这些人工复盘结论，避免重复输出已被确认的误报模式。
            只有确认影响血缘准确性或证据不足且需要人工判断时，才返回 CONFIRMED 或 NEEDS_REVIEW；规则阈值误报应返回 REJECTED。
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
            必须严格按关系类型定义判断每一条 programRelation 的含义，不得把 CASE_WHEN/FILTERS/JOINS 等影响关系当成缺少 DERIVES_TO。
            如果提供了历史走查记忆，必须优先参考这些人工复盘结论，避免重复输出已被确认的误报模式。
            重点检查：
            1. 是否漏掉 SELECT、JOIN、WHERE、CASE、GROUP BY、ORDER BY、函数参数中的来源字段或来源表；
            2. 是否把不相关字段/表错误连接到目标字段/表；
            3. 目标字段是否对错位；
            4. 关系类型是否错误，例如数据派生、过滤、关联、分组、排序、条件。
            严禁输出笼统结论，例如“主表 SMTMODS.L_ACCT_LOAN 完全未出现在程序抽取的血缘关系中”。
            每条正式疑点必须聚焦到一个具体目标字段，说明“目标字段 -> 程序当前来源 -> SQL 中应有来源 -> 判断依据”。
            如果同一个主表影响多个字段，请拆成多条字段级疑点；不要合并成表级概述。
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
                  "reason": "字段级说明，必须包含目标字段、程序当前来源或缺失状态、SQL中应有来源、为什么不一致",
                  "suggestedSources": ["schema.table.column"],
                  "evidenceRefs": ["必须引用具体字段级 SQL 表达式或程序关系，例如 target_col <= source_alias.source_col"]
                }
              ]
            }
            如果程序结果正确，请只返回一个 NO_ISSUE 且 verdict 为 REJECTED。
            每一条疑点必须明确 targetTable；MISSING_SOURCE、WRONG_SOURCE、WRONG_TARGET、WRONG_RELATION_TYPE 必须明确 targetColumn。
            只有存储过程调用、整表 INSERT/DELETE 等确实无法定位字段的场景，才允许 targetColumn 为 null。
            CONFIRMED 或 NEEDS_REVIEW 必须提供 evidenceRefs，证据必须来自 sqlSnippet 的原文片段或 programRelations 中的具体关系。
            CONFIRMED 或 NEEDS_REVIEW 的 suggestedSources 必须精确到字段级 schema.table.column；只有表名没有字段名的来源不算有效证据。
            如果无法给出具体证据，不要列为疑点；常量、字符串字面量、数字字面量、存储过程参数或变量不是缺失的表字段来源。
            如果目标字段由 CASE WHEN 的 THEN/ELSE 常量、字面量或分类值生成，WHEN 条件字段使用 CASE_WHEN 已是正确关系；不得以缺少 DERIVES_TO 为理由列为疑点。
            如果证据不足，请不要输出该疑点，或返回 NO_ISSUE 且 verdict 为 REJECTED。
            """;

    private final AiClient aiClient;
    private final AiApiConfigService aiApiConfigService;
    private final ObjectMapper objectMapper;
    private final LineageReviewMemoryMapper memoryMapper;

    public LineageReviewAiService(AiClient aiClient,
            AiApiConfigService aiApiConfigService,
            ObjectMapper objectMapper,
            LineageReviewMemoryMapper memoryMapper) {
        this.aiClient = aiClient;
        this.aiApiConfigService = aiApiConfigService;
        this.objectMapper = objectMapper;
        this.memoryMapper = memoryMapper;
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

    public String summarizeFalsePositiveMemories(List<LineageReviewIssue> falsePositiveIssues) {
        String fallback = buildFallbackFalsePositiveSummary(falsePositiveIssues);
        try {
            String response = aiClient.chat("""
                    你是一名 SQL 血缘走查复盘助手。
                    请把多次人工确认的误报样本合并成一份可复用的走查记忆。
                    要求：
                    1. 只提炼共性规则，不逐条复述样本；
                    2. 内容简洁，突出下次判定准则；
                    3. 总长度必须小于 8000 个字符；
                    4. 输出 Markdown，不要输出 JSON。
                    """, buildFalsePositiveSummaryPrompt(falsePositiveIssues));
            return limitMemoryContent(StringUtils.hasText(response) ? response.trim() : fallback);
        } catch (Exception ex) {
            return limitMemoryContent(fallback + "\n\n> AI 汇总生成失败，已使用规则化模板：" + ex.getMessage());
        }
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

                [关系类型说明]
                %s

                [历史走查记忆]
                %s

                [证据包]
                %s
                """.formatted(
                draftIssue.getTableName(),
                draftIssue.getColumnName(),
                draftIssue.getIssueType(),
                draftIssue.getSeverity(),
                draftIssue.getRuleHits(),
                RELATION_TYPE_GUIDE,
                loadActiveReviewMemory(),
                toJson(evidence));
    }

    private String buildSqlAuditPrompt(Map<String, Object> evidence) {
        return """
                请对照以下 SQL 和程序抽取出的血缘关系，判断是否存在遗漏或错误。

                [关系类型说明]
                %s

                [历史走查记忆]
                %s

                [证据包]
                %s
                """.formatted(RELATION_TYPE_GUIDE, loadActiveReviewMemory(), toJson(evidence));
    }

    private String buildFalsePositiveSummaryPrompt(List<LineageReviewIssue> falsePositiveIssues) {
        return """
                请基于以下人工误报样本，生成一条合并后的走查记忆。

                输出结构：
                ## 适用场景
                - ...
                ## 误报模式
                - ...
                ## 下次判定准则
                - ...
                ## 证据线索
                - ...

                [人工误报样本]
                %s
                """.formatted(limitPromptSamples(toJson(buildFalsePositiveSummaryEvidence(falsePositiveIssues))));
    }

    private List<Map<String, Object>> buildFalsePositiveSummaryEvidence(List<LineageReviewIssue> falsePositiveIssues) {
        if (falsePositiveIssues == null || falsePositiveIssues.isEmpty()) {
            return List.of();
        }
        return falsePositiveIssues.stream()
                .map(issue -> {
                    Map<String, Object> evidence = new LinkedHashMap<>();
                    evidence.put("target", buildIssueTarget(issue));
                    evidence.put("issueType", issue.getIssueType());
                    evidence.put("ruleHits", issue.getRuleHits());
                    evidence.put("aiReason", issue.getReason());
                    evidence.put("manualReason", issue.getReviewerNote());
                    evidence.put("evidenceRefs", issue.getEvidenceRefs());
                    return evidence;
                })
                .toList();
    }

    private String buildFallbackFalsePositiveSummary(List<LineageReviewIssue> falsePositiveIssues) {
        Map<String, Long> issueTypeCounts = falsePositiveIssues == null ? Map.of() : falsePositiveIssues.stream()
                .collect(Collectors.groupingBy(this::normalizeIssueType, LinkedHashMap::new, Collectors.counting()));
        List<String> manualReasons = falsePositiveIssues == null ? List.of() : falsePositiveIssues.stream()
                .map(LineageReviewIssue::getReviewerNote)
                .filter(StringUtils::hasText)
                .distinct()
                .limit(12)
                .toList();
        String summary = """
                ## 适用场景
                - 人工已确认的 SQL 血缘走查误报样本，主要疑点类型：%s

                ## 误报模式
                %s

                ## 下次判定准则
                - 优先核对关系类型定义，CASE_WHEN、FILTERS、JOINS、GROUPS、ORDERS 这类影响关系不要误判为缺少 DERIVES_TO。
                - 只有能从 SQL 片段或程序关系列表定位到具体字段级缺失、错连或类型错误时，才输出正式疑点。
                - 证据不足、只有表级笼统判断、或无法给出字段级 suggestedSources 时，不要输出 CONFIRMED 疑点。

                ## 证据线索
                - 参考人工误报原因和字段级证据，不逐条复述历史样本。
                """.formatted(
                issueTypeCounts,
                manualReasons.isEmpty()
                        ? "- 历史误报原因较少，按关系类型和字段级证据约束优先判断。"
                        : manualReasons.stream().map(reason -> "- " + reason).collect(Collectors.joining("\n")));
        return limitMemoryContent(summary);
    }

    private String limitMemoryContent(String content) {
        if (!StringUtils.hasText(content) || content.length() <= SUMMARY_MEMORY_CHAR_LIMIT) {
            return content;
        }
        return content.substring(0, SUMMARY_MEMORY_CHAR_LIMIT - 16) + "\n\n[记忆已截断]";
    }

    private String limitPromptSamples(String content) {
        if (!StringUtils.hasText(content) || content.length() <= SUMMARY_PROMPT_SAMPLE_CHAR_LIMIT) {
            return content;
        }
        return content.substring(0, SUMMARY_PROMPT_SAMPLE_CHAR_LIMIT) + "\n\n[误报样本已截断]";
    }

    private String normalizeIssueType(LineageReviewIssue issue) {
        return StringUtils.hasText(issue.getIssueType()) ? issue.getIssueType() : "UNKNOWN";
    }

    private String buildIssueTarget(LineageReviewIssue issue) {
        if (!StringUtils.hasText(issue.getColumnName())) {
            return StringUtils.hasText(issue.getTableName()) ? issue.getTableName() : "UNKNOWN_TABLE";
        }
        return issue.getTableName() + "." + issue.getColumnName();
    }

    private String loadActiveReviewMemory() {
        try {
            LambdaQueryWrapper<LineageReviewMemory> query = new LambdaQueryWrapper<>();
            query.eq(LineageReviewMemory::getStatus, "ACTIVE")
                    .orderByDesc(LineageReviewMemory::getUpdateTime)
                    .last("LIMIT " + MEMORY_LIMIT);
            List<LineageReviewMemory> memories = memoryMapper.selectList(query);
            if (memories == null || memories.isEmpty()) {
                return "暂无历史走查记忆。";
            }
            String content = memories.stream()
                    .filter(memory -> StringUtils.hasText(memory.getContent()))
                    .map(memory -> "### " + memory.getTitle() + "\n" + memory.getContent())
                    .collect(Collectors.joining("\n\n"));
            if (content.length() <= MEMORY_PROMPT_CHAR_LIMIT) {
                return content;
            }
            return content.substring(0, MEMORY_PROMPT_CHAR_LIMIT) + "\n\n[历史走查记忆已截断]";
        } catch (Exception ex) {
            return "历史走查记忆读取失败，本次按当前证据独立判断：" + ex.getMessage();
        }
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

    private String toJson(Object evidence) {
        try {
            return objectMapper.writerWithDefaultPrettyPrinter().writeValueAsString(evidence);
        } catch (Exception ex) {
            return String.valueOf(evidence);
        }
    }
}
