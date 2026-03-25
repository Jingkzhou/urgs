package com.example.urgs_api.sql.dto;

import lombok.Data;

import java.util.List;
import java.util.Map;

@Data
public class SqlExecuteResponse {
    private boolean success;
    private List<String> columns;
    private List<Map<String, Object>> data;
    private String error;
    private long executionTimeMs;
    private int page;
    private int pageSize;
    private long totalRows;
}
