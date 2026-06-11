package com.example.urgs_api.metadata.service;

import static org.junit.jupiter.api.Assertions.assertEquals;

import java.util.Map;

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
}
