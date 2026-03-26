package com.example.urgs_api.sql.dto;

import lombok.Data;

import java.util.List;

@Data
public class SchemaMetadataResponse {
    private boolean success = true;
    private String error;
    private List<TableMeta> tables;

    @Data
    public static class TableMeta {
        private String tableName;
        private List<ColumnMeta> columns;
    }

    @Data
    public static class ColumnMeta {
        private String columnName;
        private String dataType;
        private String comment;
    }
}
