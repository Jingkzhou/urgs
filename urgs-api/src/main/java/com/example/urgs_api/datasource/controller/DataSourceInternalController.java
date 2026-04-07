package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.datasource.dto.ResolvedDataSourceConfigDTO;
import com.example.urgs_api.datasource.service.DynamicDataSourceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/datasource")
public class DataSourceInternalController {

    @Autowired
    private DynamicDataSourceService dynamicDataSourceService;

    @GetMapping("/config/{id}/resolved")
    public ResolvedDataSourceConfigDTO getResolvedConfig(@PathVariable Long id) {
        return dynamicDataSourceService.resolveConfig(id);
    }
}
