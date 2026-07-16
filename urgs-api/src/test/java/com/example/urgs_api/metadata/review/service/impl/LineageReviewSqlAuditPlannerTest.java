package com.example.urgs_api.metadata.review.service.impl;

import org.junit.jupiter.api.Test;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class LineageReviewSqlAuditPlannerTest {

    private final LineageReviewSqlAuditPlanner planner = new LineageReviewSqlAuditPlanner();

    @Test
    void classifiesAmbiguousSelectStarAsHighRisk() {
        Map<String, Object> sqlObject = new LinkedHashMap<>();
        sqlObject.put("snippet", "INSERT INTO DWS.T SELECT * FROM ODS.S");
        sqlObject.put("sourceFiles", List.of("etl/job.sql"));
        sqlObject.put("programRelations", List.of(Map.of(
                "sourceTable", "ODS.S",
                "targetTable", "DWS.T",
                "ambiguityCode", "AMBIGUOUS_COLUMN")));

        LineageReviewSqlAuditPlanner.RiskAssessment risk = planner.assess(sqlObject);

        assertThat(risk.highRisk()).isTrue();
        assertThat(risk.score()).isGreaterThanOrEqualTo(60);
        assertThat(risk.reasons()).contains("METADATA_AMBIGUITY", "SELECT_STAR");
        assertThat(risk.contextGroupId()).isEqualTo("etl/job.sql");
    }

    @Test
    void createsDynamicMicroBatchesWithoutMixingContextGroups() {
        List<Map<String, Object>> evidencePackages = new ArrayList<>();
        for (int i = 0; i < 9; i++) {
            evidencePackages.add(evidence("a-" + i, "job-a.sql", i));
        }
        evidencePackages.add(evidence("b-1", "job-b.sql", 99));

        List<List<Map<String, Object>>> batches = planner.buildScreeningBatches(evidencePackages);

        assertThat(batches).hasSize(3);
        assertThat(batches).allSatisfy(batch -> {
            assertThat(batch).hasSizeLessThanOrEqualTo(LineageReviewSqlAuditPlanner.MAX_SCREENING_BATCH_SIZE);
            assertThat(batch.stream().map(item -> item.get("contextGroupId")).distinct().count()).isEqualTo(1);
        });
        assertThat(batches.get(0).get(0).get("contextGroupId")).isEqualTo("job-b.sql");
    }

    @Test
    void doesNotTreatAggregateStarAsProjectionWildcard() {
        Map<String, Object> sqlObject = new LinkedHashMap<>();
        sqlObject.put("snippet", "SELECT COUNT(*) AS TOTAL FROM ODS.S");
        sqlObject.put("programRelations", List.of());

        LineageReviewSqlAuditPlanner.RiskAssessment risk = planner.assess(sqlObject);

        assertThat(risk.reasons()).doesNotContain("SELECT_STAR");
    }

    @Test
    void returnsOnlyAdjacentStatementsFromSameContext() {
        Map<String, Object> first = evidence("stmt-1", "job.sql", 0);
        Map<String, Object> current = evidence("stmt-2", "job.sql", 0);
        Map<String, Object> third = evidence("stmt-3", "job.sql", 0);
        Map<String, Object> other = evidence("stmt-4", "other.sql", 0);

        List<Map<String, Object>> context = planner.neighborContext(
                List.of(first, current, third, other), current);

        assertThat(context).extracting(item -> item.get("statementUid"))
                .containsExactly("stmt-1", "stmt-3");
    }

    private Map<String, Object> evidence(String statementUid, String contextGroupId, int riskScore) {
        Map<String, Object> evidence = new LinkedHashMap<>();
        evidence.put("statementUid", statementUid);
        evidence.put("statementHash", statementUid);
        evidence.put("contextGroupId", contextGroupId);
        evidence.put("riskScore", riskScore);
        evidence.put("sqlSnippet", "SELECT 1");
        evidence.put("programRelations", List.of());
        return evidence;
    }
}
