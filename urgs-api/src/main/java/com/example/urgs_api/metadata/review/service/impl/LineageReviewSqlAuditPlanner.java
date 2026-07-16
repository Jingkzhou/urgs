package com.example.urgs_api.metadata.review.service.impl;

import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.Objects;
import java.util.Set;

@Service
public class LineageReviewSqlAuditPlanner {

    static final int HIGH_RISK_THRESHOLD = 20;
    static final int MAX_SCREENING_BATCH_SIZE = 8;
    static final int MAX_SCREENING_BATCH_CHARS = 50000;

    public RiskAssessment assess(Map<String, Object> sqlObject) {
        String sql = text(sqlObject.get("snippet"));
        List<Map<String, Object>> relations = relationMaps(sqlObject.get("programRelations"));
        int score = 0;
        Set<String> reasons = new LinkedHashSet<>();

        if (relations.stream().anyMatch(rel -> StringUtils.hasText(text(rel.get("ambiguityCode"))))) {
            score += 40;
            reasons.add("METADATA_AMBIGUITY");
        }
        if (relations.stream().anyMatch(rel -> "LOW".equalsIgnoreCase(text(rel.get("confidence"))))) {
            score += 30;
            reasons.add("LOW_CONFIDENCE_RELATION");
        }
        if (relations.stream().anyMatch(rel -> !StringUtils.hasText(text(rel.get("targetColumn")))
                && (StringUtils.hasText(text(rel.get("sourceColumn"))) || rel.get("projectionIndex") != null))) {
            score += 25;
            reasons.add("IMPLICIT_TARGET_MAPPING");
        }
        String normalizedSql = sql == null ? "" : sql.toUpperCase(Locale.ROOT);
        if (containsProjectionWildcard(normalizedSql)) {
            score += 20;
            reasons.add("SELECT_STAR");
        }
        if (normalizedSql.contains("EXECUTE IMMEDIATE")
                || normalizedSql.contains("PREPARE ")
                || normalizedSql.contains("EXECUTE ")) {
            score += 20;
            reasons.add("DYNAMIC_SQL");
        }
        if (relations.stream().anyMatch(rel -> StringUtils.hasText(text(rel.get("validationNote"))))) {
            score += 15;
            reasons.add("PARSER_VALIDATION_WARNING");
        }
        if (sql != null && sql.length() > 12000) {
            score += 10;
            reasons.add("LONG_SQL");
        }
        if (relations.size() > 50) {
            score += 10;
            reasons.add("HIGH_RELATION_COMPLEXITY");
        }

        String contextGroupId = contextGroupId(sqlObject);
        return new RiskAssessment(score, score >= HIGH_RISK_THRESHOLD, new ArrayList<>(reasons), contextGroupId);
    }

    private boolean containsProjectionWildcard(String normalizedSql) {
        int selectIndex = normalizedSql.indexOf("SELECT");
        if (selectIndex < 0) {
            return false;
        }
        int fromIndex = normalizedSql.indexOf(" FROM ", selectIndex + 6);
        if (fromIndex < 0) {
            return false;
        }
        String projection = normalizedSql.substring(selectIndex + 6, fromIndex)
                .replaceFirst("^\\s*DISTINCT\\s+", "");
        return projection.matches("(?s).*(^|,)\\s*(?:[A-Z0-9_$]+\\.)?\\*\\s*(?:,|$).*");
    }

    public List<List<Map<String, Object>>> buildScreeningBatches(List<Map<String, Object>> evidencePackages) {
        Map<String, List<Map<String, Object>>> groups = new LinkedHashMap<>();
        for (Map<String, Object> evidence : evidencePackages) {
            String contextGroupId = text(evidence.get("contextGroupId"));
            groups.computeIfAbsent(StringUtils.hasText(contextGroupId) ? contextGroupId : "GLOBAL",
                    ignored -> new ArrayList<>()).add(evidence);
        }

        List<List<Map<String, Object>>> batches = new ArrayList<>();
        groups.values().stream()
                .sorted(Comparator.comparingInt(this::maxRiskScore).reversed())
                .forEach(group -> {
                    group.sort(Comparator.comparingInt(this::riskScore).reversed());
                    List<Map<String, Object>> current = new ArrayList<>();
                    int currentChars = 0;
                    for (Map<String, Object> evidence : group) {
                        int nextChars = estimateChars(evidence);
                        if (!current.isEmpty()
                                && (current.size() >= MAX_SCREENING_BATCH_SIZE
                                || currentChars + nextChars > MAX_SCREENING_BATCH_CHARS)) {
                            batches.add(current);
                            current = new ArrayList<>();
                            currentChars = 0;
                        }
                        current.add(evidence);
                        currentChars += nextChars;
                    }
                    if (!current.isEmpty()) {
                        batches.add(current);
                    }
                });
        return batches;
    }

    public List<Map<String, Object>> neighborContext(
            List<Map<String, Object>> evidencePackages,
            Map<String, Object> currentEvidence) {
        String currentUid = text(currentEvidence.get("statementUid"));
        String contextGroupId = text(currentEvidence.get("contextGroupId"));
        List<Map<String, Object>> sameContext = evidencePackages.stream()
                .filter(item -> Objects.equals(contextGroupId, text(item.get("contextGroupId"))))
                .toList();
        int currentIndex = -1;
        for (int i = 0; i < sameContext.size(); i++) {
            if (Objects.equals(currentUid, text(sameContext.get(i).get("statementUid")))) {
                currentIndex = i;
                break;
            }
        }
        if (currentIndex < 0) {
            return List.of();
        }
        List<Map<String, Object>> context = new ArrayList<>();
        for (int i = Math.max(0, currentIndex - 1); i <= Math.min(sameContext.size() - 1, currentIndex + 1); i++) {
            Map<String, Object> item = sameContext.get(i);
            if (Objects.equals(currentUid, text(item.get("statementUid")))) {
                continue;
            }
            Map<String, Object> compact = new LinkedHashMap<>();
            compact.put("statementUid", item.get("statementUid"));
            compact.put("statementHash", item.get("statementHash"));
            compact.put("sqlSnippet", item.get("sqlSnippet"));
            compact.put("sourceFiles", item.get("sourceFiles"));
            context.add(compact);
        }
        return context;
    }

    private int maxRiskScore(List<Map<String, Object>> group) {
        return group.stream().mapToInt(this::riskScore).max().orElse(0);
    }

    private int riskScore(Map<String, Object> evidence) {
        Object value = evidence.get("riskScore");
        return value instanceof Number number ? number.intValue() : 0;
    }

    private int estimateChars(Map<String, Object> evidence) {
        return String.valueOf(evidence).length();
    }

    private String contextGroupId(Map<String, Object> sqlObject) {
        Object sourceFilesValue = sqlObject.get("sourceFiles");
        if (sourceFilesValue instanceof List<?> files) {
            for (Object file : files) {
                if (file != null && StringUtils.hasText(String.valueOf(file))) {
                    return String.valueOf(file).trim();
                }
            }
        }
        List<Map<String, Object>> relations = relationMaps(sqlObject.get("programRelations"));
        return relations.stream()
                .map(rel -> text(rel.get("targetTable")))
                .filter(StringUtils::hasText)
                .findFirst()
                .orElse("GLOBAL");
    }

    private List<Map<String, Object>> relationMaps(Object value) {
        if (!(value instanceof List<?> list)) {
            return List.of();
        }
        List<Map<String, Object>> result = new ArrayList<>();
        for (Object item : list) {
            if (!(item instanceof Map<?, ?> raw)) {
                continue;
            }
            Map<String, Object> relation = new LinkedHashMap<>();
            raw.forEach((key, mapValue) -> {
                if (key != null) {
                    relation.put(String.valueOf(key), mapValue);
                }
            });
            result.add(relation);
        }
        return result;
    }

    private String text(Object value) {
        if (value == null) {
            return null;
        }
        String text = String.valueOf(value);
        return StringUtils.hasText(text) ? text.trim() : null;
    }

    public record RiskAssessment(int score, boolean highRisk, List<String> reasons, String contextGroupId) {
    }
}
