package com.example.urgs_api.sql.controller;

import com.example.urgs_api.sql.dto.SchemaMetadataResponse;
import com.example.urgs_api.sql.dto.SqlExecuteRequest;
import com.example.urgs_api.sql.dto.SqlExecuteResponse;
import com.example.urgs_api.sql.service.SqlConsoleService;
import com.example.urgs_api.auth.annotation.RequirePermission;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sql")
public class SqlConsoleController {

    @Autowired
    private SqlConsoleService sqlConsoleService;

    @PostMapping("/execute")
    @RequirePermission("metadata:query")
    public SqlExecuteResponse execute(@RequestBody SqlExecuteRequest request) {
        return sqlConsoleService.executeSql(
                request.getSql(),
                request.getDataSourceId(),
                request.getPage(),
                request.getPageSize()
        );
    }

    @GetMapping("/schema")
    @RequirePermission("metadata:query")
    public SchemaMetadataResponse getSchema(@RequestParam(required = false) Long dataSourceId) {
        return sqlConsoleService.getSchemaMetadata(dataSourceId);
    }
}
