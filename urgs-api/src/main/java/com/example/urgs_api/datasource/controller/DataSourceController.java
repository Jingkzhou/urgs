package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.datasource.dto.ResolvedDataSourceConfigDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.service.DataSourceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/datasource")
public class DataSourceController {

    @Autowired
    private DataSourceService dataSourceService;

    @Autowired
    private com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    @PostMapping("/test")
    public org.springframework.http.ResponseEntity<String> testConnection(@RequestBody DataSourceConfig config) {
        try {
            dynamicDataSourceService.testConnection(config);
            return org.springframework.http.ResponseEntity.ok("Connection successful!");
        } catch (Exception e) {
            log.error("Test connection failed for config: {}", config, e);
            return org.springframework.http.ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/meta")
    public List<DataSourceMeta> getMeta() {
        return dataSourceService.getAllMeta();
    }

    @GetMapping("/config")
    public List<DataSourceConfig> getConfigs() {
        return dataSourceService.getAllConfigs();
    }

    @GetMapping("/config/{id}/resolved")
    public ResolvedDataSourceConfigDTO getResolvedConfig(@PathVariable Long id) {
        return dynamicDataSourceService.resolveConfig(id);
    }

    @PostMapping("/config")
    public boolean createConfig(@RequestBody DataSourceConfig config) {
        return dataSourceService.save(config);
    }

    @PutMapping("/config/{id}")
    public boolean updateConfig(@PathVariable Long id, @RequestBody DataSourceConfig config) {
        config.setId(id);
        return dataSourceService.updateById(config);
    }

    @DeleteMapping("/config/{id}")
    public boolean deleteConfig(@PathVariable Long id) {
        return dataSourceService.removeById(id);
    }
}
