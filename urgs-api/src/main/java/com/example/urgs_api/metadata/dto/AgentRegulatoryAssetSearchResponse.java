package com.example.urgs_api.metadata.dto;

import java.time.LocalDateTime;
import java.util.List;

public record AgentRegulatoryAssetSearchResponse(
        List<Item> items,
        int count,
        List<String> effectiveSystemCodes,
        String traceId) {

    public record Item(
            String assetId,
            String tableCode,
            String tableName,
            String systemCode,
            String subjectCode,
            String subjectName,
            String summary,
            List<Evidence> evidence) {
    }

    public record Evidence(
            String source,
            String sourceId,
            LocalDateTime updatedAt) {
    }
}
