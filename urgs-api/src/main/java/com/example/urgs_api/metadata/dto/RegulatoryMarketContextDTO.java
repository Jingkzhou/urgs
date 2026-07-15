package com.example.urgs_api.metadata.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

public final class RegulatoryMarketContextDTO {

    private RegulatoryMarketContextDTO() {
    }

    public record SearchItem(
            String assetType,
            String assetId,
            String parentId,
            String systemCode,
            String name,
            String cnName,
            String description,
            LocalDateTime updateTime) {
    }

    public record SearchResponse(String keyword, List<SearchItem> items, boolean truncated) {
    }

    public record CatalogScanRequest(
            String requirement,
            List<String> keywords,
            List<String> exactIdentifiers,
            List<String> systemCodes,
            Integer limit,
            String allowedSystems) {
    }

    public record CatalogCandidate(
            String tableId,
            String systemCode,
            String name,
            String cnName,
            String subjectName,
            String theme,
            String frequency,
            String businessCaliber,
            List<PhysicalTableBindingDTO> physicalTables,
            int score,
            List<String> hitReasons,
            LocalDateTime updateTime) {
    }

    public record CatalogScanResponse(
            String requirement,
            int scannedTableCount,
            Map<String, Long> systemTableCounts,
            List<CatalogCandidate> candidates,
            boolean truncated,
            List<String> evidence) {
    }

    public record CodeValue(
            String code,
            String name,
            String parentCode,
            String level,
            String description,
            LocalDate startDate,
            LocalDate endDate) {
    }

    public record CodeTableContext(
            String tableCode,
            String tableName,
            String systemCode,
            String description,
            List<CodeValue> values,
            long total,
            boolean truncated) {
    }

    public record ElementContext(
            String id,
            String tableId,
            String type,
            String name,
            String cnName,
            String dataType,
            String length,
            Integer nullable,
            Integer isPk,
            Integer isDesensitized,
            String formula,
            String codeSnippet,
            String codeTableCode,
            String valueRange,
            String validationRule,
            String businessCaliber,
            String fillInstruction,
            String devNotes,
            List<PhysicalFieldBindingDTO> physicalFields,
            CodeTableContext codeTable,
            LocalDateTime updateTime) {
    }

    public record TableContext(
            String id,
            String systemCode,
            String name,
            String cnName,
            String subjectCode,
            String subjectName,
            String theme,
            String frequency,
            String queryTableType,
            String businessCaliber,
            String fillInstruction,
            String devNotes,
            List<PhysicalTableBindingDTO> physicalTables,
            List<ElementContext> elements,
            long elementCount,
            boolean elementsTruncated,
            LocalDateTime updateTime) {
    }

    public record Relationship(
            String relationType,
            List<String> regulatoryTableIds,
            String physicalTable,
            boolean confirmed,
            String note) {
    }

    public record RelationshipResponse(List<Relationship> relationships, List<String> warnings) {
    }

    public record RelationshipRequest(List<Long> tableIds, String allowedSystems) {
    }

    public record DevelopmentContextRequest(
            String requirement,
            List<String> keywords,
            List<Long> tableIds,
            List<Long> elementIds,
            String allowedSystems) {
    }

    public record DevelopmentContextResponse(
            String requirement,
            List<TableContext> tables,
            List<ElementContext> selectedElements,
            List<String> missingInformation,
            List<String> evidence) {
    }

    public record CodeValueCheck(String tableCode, String code) {
    }

    public record SqlValidationRequest(
            String sql,
            List<CodeValueCheck> codeChecks,
            String allowedSystems) {
    }

    public record SqlValidationResult(
            boolean valid,
            List<String> statementTypes,
            List<String> referencedTables,
            List<String> checkedColumns,
            List<String> errors,
            List<String> warnings) {
    }
}
