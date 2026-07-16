package com.example.urgs_api.metadata.dto;

import lombok.Data;

import java.util.List;

@Data
public class LineageRelationEvidenceRequest {
    private String relationId;
    private List<String> statementUids;
    private String sourceTable;
    private String sourceColumn;
    private String targetTable;
    private String targetColumn;
    private String relationType;
}
