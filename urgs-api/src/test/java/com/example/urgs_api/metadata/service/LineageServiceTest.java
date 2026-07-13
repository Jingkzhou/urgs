package com.example.urgs_api.metadata.service;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.util.Map;
import java.util.List;

import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

class LineageServiceTest {

    private final LineageService lineageService = new LineageService();

    @Test
    void preservesDotsInsideExplicitTableName() {
        String tableName = ReflectionTestUtils.invokeMethod(
                lineageService,
                "resolveTableName",
                Map.of("name", "PM_RSDATA.S75_1.B", "tableName", "S75_1.B"),
                "PM_RSDATA.S75_1.B");

        assertEquals("S75_1.B", tableName);
    }

    @Test
    void fallsBackToQualifiedNameForLegacyNodes() {
        String tableName = ReflectionTestUtils.invokeMethod(
                lineageService,
                "resolveTableName",
                Map.of("name", "PM_RSDATA.LEGACY_TABLE"),
                "PM_RSDATA.LEGACY_TABLE");

        assertEquals("LEGACY_TABLE", tableName);
    }

    @Test
    void capsTraversalDepthToProtectLargeGraphs() {
        assertEquals(30, (Integer) ReflectionTestUtils.invokeMethod(lineageService, "normalizeDepth", 500));
        assertEquals(30, (Integer) ReflectionTestUtils.invokeMethod(lineageService, "normalizeDepth", -1));
        assertEquals(1, (Integer) ReflectionTestUtils.invokeMethod(lineageService, "normalizeDepth", 0));
    }

    @Test
    void normalizesSearchNodeTypesAgainstWhitelist() {
        List<String> types = ReflectionTestUtils.invokeMethod(
                lineageService,
                "normalizeNodeTypes",
                List.of("table", "column", "unsupported", "table"));

        assertEquals(List.of("TABLE", "COLUMN"), types);
    }

    @Test
    void graphLookupPrefersStableObjectUid() {
        String clause = ReflectionTestUtils.invokeMethod(lineageService, "buildTableMatchClause", "n");

        assertTrue(clause.contains("n.objectUid"));
        assertTrue(clause.contains("$objectUid"));
        assertEquals(clause.chars().filter(value -> value == '(').count(),
                clause.chars().filter(value -> value == ')').count());
    }

    @Test
    void columnTraversalUsesParentObjectUidWhenProvided() {
        String scopedClause = ReflectionTestUtils.invokeMethod(
                lineageService, "buildColumnStartClause", "source-100-table-uid");
        String legacyClause = ReflectionTestUtils.invokeMethod(
                lineageService, "buildColumnStartClause", "");

        assertTrue(scopedClause.contains("centerTable:Table {objectUid: $objectUid}"));
        assertTrue(scopedClause.contains("BELONGS_TO"));
        assertTrue(legacyClause.contains("table: $tableName"));
    }
}
