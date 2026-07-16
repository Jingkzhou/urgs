package com.example.urgs_api.metadata.review.service;

import com.example.urgs_api.ai.client.AiClient;
import com.example.urgs_api.metadata.review.dto.LineageReviewAuditResult;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigDecimal;
import java.util.ArrayDeque;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Queue;

import static org.assertj.core.api.Assertions.assertThat;

class LineageReviewAiServiceTest {

    @Test
    void keepsOnlyTwoPassVerdictWithGroundedEvidence() {
        LineageReviewAiService service = serviceWith(
                issueResponse("NEEDS_REVIEW", 0.72, List.of("SQL-L001", "PR-001")),
                issueResponse("CONFIRMED", 0.91, List.of("SQL-L001", "PR-001")));

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getAiCallCount()).isEqualTo(2);
        assertThat(result.getVerdicts()).hasSize(1);
        assertThat(result.getVerdicts().get(0).getVerdict()).isEqualTo("CONFIRMED");
        assertThat(result.getVerdicts().get(0).getConfidence()).isEqualByComparingTo(new BigDecimal("0.9100"));
        assertThat(result.getVerdicts().get(0).getEvidenceRefs()).containsExactly("SQL-L001", "PR-001");
        assertThat(result.getVerdicts().get(0).getSummary()).isEqualTo("目标字段来源解析错误");
    }

    @Test
    void dropsVerdictWhenEvidenceIdIsNotInCurrentEvidencePack() {
        LineageReviewAiService service = serviceWith(
                issueResponse("NEEDS_REVIEW", 0.72, List.of("SQL-L001", "PR-001")),
                issueResponse("CONFIRMED", 0.95, List.of("SQL-L999", "PR-999")));

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.isSuccess()).isTrue();
        assertThat(result.getVerdicts()).isEmpty();
    }

    @Test
    void reportsAiProtocolFailureInsteadOfCreatingFakeManualIssue() {
        LineageReviewAiService service = serviceWith(
                issueResponse("NEEDS_REVIEW", 0.72, List.of("SQL-L001", "PR-001")),
                "not-json");

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.isSuccess()).isFalse();
        assertThat(result.getAiCallCount()).isEqualTo(2);
        assertThat(result.getVerdicts()).isEmpty();
        assertThat(result.getFailureReason()).contains("AI 返回");
    }

    @Test
    void downgradesLowConfidenceConfirmationToManualReview() {
        LineageReviewAiService service = serviceWith(
                issueResponse("NEEDS_REVIEW", 0.72, List.of("SQL-L001", "PR-001")),
                issueResponse("CONFIRMED", 0.76, List.of("SQL-L001", "PR-001")));

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.getVerdicts()).hasSize(1);
        assertThat(result.getVerdicts().get(0).getVerdict()).isEqualTo("NEEDS_REVIEW");
        assertThat(result.getVerdicts().get(0).getConfidence()).isEqualByComparingTo(new BigDecimal("0.7600"));
    }

    @Test
    void allowsMissingSourceWithSqlEvidenceWhenNoRelationCanExist() {
        LineageReviewAiService service = serviceWith(
                issueResponseFor("MISSING_SOURCE", "NEEDS_REVIEW", 0.70, List.of("SQL-L001")),
                issueResponseFor("MISSING_SOURCE", "CONFIRMED", 0.88, List.of("SQL-L001")));

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.getVerdicts()).hasSize(1);
        assertThat(result.getVerdicts().get(0).getIssueType()).isEqualTo("MISSING_SOURCE");
    }

    @Test
    void dropsWrongSourceWithoutProgramOrGraphRelationEvidence() {
        LineageReviewAiService service = serviceWith(
                issueResponse("NEEDS_REVIEW", 0.72, List.of("SQL-L001", "PR-001")),
                issueResponse("CONFIRMED", 0.95, List.of("SQL-L001")));

        LineageReviewAuditResult result = service.auditSqlLineage(evidence());

        assertThat(result.getVerdicts()).isEmpty();
    }

    private LineageReviewAiService serviceWith(String... responses) {
        return new LineageReviewAiService(
                new SequencedAiClient(responses),
                null,
                new ObjectMapper(),
                null);
    }

    private Map<String, Object> evidence() {
        return Map.of(
                "sqlLines", List.of(Map.of(
                        "evidenceId", "SQL-L001",
                        "lineNumber", 1,
                        "text", "INSERT INTO DWS.TARGET_T (AMOUNT) SELECT S.AMOUNT FROM ODS.SOURCE_T S")),
                "programRelations", List.of(Map.of(
                        "evidenceId", "PR-001",
                        "sourceTable", "ODS.WRONG_T",
                        "sourceColumn", "AMOUNT",
                        "targetTable", "DWS.TARGET_T",
                        "targetColumn", "AMOUNT",
                        "relationType", "DERIVES_TO")),
                "graphFieldRelations", List.of()
        );
    }

    private String issueResponse(String verdict, double confidence, List<String> evidenceRefs) {
        return issueResponseFor("WRONG_SOURCE", verdict, confidence, evidenceRefs);
    }

    private String issueResponseFor(String issueType, String verdict, double confidence, List<String> evidenceRefs) {
        return """
                {
                  "issues": [{
                    "issueType": "%s",
                    "targetTable": "DWS.TARGET_T",
                    "targetColumn": "AMOUNT",
                    "severity": "HIGH",
                    "confidence": %s,
                    "verdict": "%s",
                    "summary": "目标字段来源解析错误",
                    "currentState": "程序连接到 ODS.WRONG_T.AMOUNT",
                    "expectedState": "SQL 显示应连接 ODS.SOURCE_T.AMOUNT",
                    "reason": "程序来源表与 SQL FROM 来源不一致",
                    "expectedRelationType": "DERIVES_TO",
                    "disposition": "调整血缘分析程序",
                    "recommendation": "检查字段别名解析",
                    "suggestedSources": ["ODS.SOURCE_T.AMOUNT"],
                    "evidenceRefs": %s
                  }]
                }
                """.formatted(issueType, confidence, verdict, toJsonArray(evidenceRefs));
    }

    private String toJsonArray(List<String> values) {
        return values.stream().map(value -> "\"" + value + "\"").collect(java.util.stream.Collectors.joining(",", "[", "]"));
    }

    private static class SequencedAiClient extends AiClient {
        private final Queue<String> responses;

        private SequencedAiClient(String... responses) {
            this.responses = new ArrayDeque<>(Arrays.asList(responses));
        }

        @Override
        public String chat(String systemPrompt, String userPrompt) {
            if (responses.isEmpty()) {
                throw new IllegalStateException("没有更多测试响应");
            }
            return responses.remove();
        }
    }
}
