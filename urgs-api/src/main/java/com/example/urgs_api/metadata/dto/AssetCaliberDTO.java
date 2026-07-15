package com.example.urgs_api.metadata.dto;

import java.time.LocalDateTime;
import java.util.List;

public final class AssetCaliberDTO {

    private AssetCaliberDTO() {
    }

    public record RegElementContext(
            Long id,
            Long tableId,
            String type,
            String name,
            String cnName,
            String dataType,
            String formula,
            String codeTableCode,
            String valueRange,
            String validationRule,
            String businessCaliber,
            String fillInstruction,
            LocalDateTime updateTime) {
    }

    public record RegTableContext(
            Long id,
            String name,
            String cnName,
            String systemCode,
            String subjectName,
            String theme,
            String frequency,
            String businessCaliber,
            String fillInstruction,
            LocalDateTime updateTime,
            List<RegElementContext> elements) {
    }

    public record ElementCaliberChange(
            Long elementId,
            LocalDateTime expectedUpdateTime,
            String businessCaliber) {
    }

    public record CaliberChangeRequest(
            Long requesterUserId,
            Long tableId,
            LocalDateTime expectedTableUpdateTime,
            String tableBusinessCaliber,
            List<ElementCaliberChange> elements,
            String reqId,
            String description,
            String sourceSql,
            boolean confirmed) {
    }

    public record ChangePreview(
            String assetType,
            Long assetId,
            String name,
            String oldValue,
            String newValue,
            LocalDateTime currentUpdateTime,
            boolean changed,
            boolean conflict) {
    }

    public record PreviewResponse(
            boolean valid,
            List<ChangePreview> changes,
            List<String> errors,
            List<String> warnings) {
    }

    public record ApplyResult(
            int updatedCount,
            int skippedCount,
            RegTableContext table,
            List<String> warnings) {
    }
}
