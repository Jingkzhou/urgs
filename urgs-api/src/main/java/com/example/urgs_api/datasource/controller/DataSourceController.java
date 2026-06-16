package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.datasource.dto.DataSourceOptionDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.service.DataSourceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/datasource")
public class DataSourceController {

    private final DataSourceService dataSourceService;
    private final com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    public DataSourceController(DataSourceService dataSourceService,
            com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService) {
        this.dataSourceService = dataSourceService;
        this.dynamicDataSourceService = dynamicDataSourceService;
    }

    @PostMapping("/test")
    @RequirePermission("datasource:list")
    public org.springframework.http.ResponseEntity<String> testConnection(@RequestBody DataSourceConfig config) {
        try {
            dynamicDataSourceService.testConnection(dataSourceService.restoreMaskedSecrets(config));
            return org.springframework.http.ResponseEntity.ok("Connection successful!");
        } catch (Exception e) {
            log.error("Test connection failed for datasource id={}, metaId={}: {}",
                    config.getId(), config.getMetaId(), e.getMessage(), e);
            return org.springframework.http.ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @GetMapping("/meta")
    public List<DataSourceMeta> getMeta() {
        return dataSourceService.getAllMeta();
    }

    @GetMapping("/config")
    @RequirePermission("datasource:list")
    public List<DataSourceConfig> getConfigs() {
        return dataSourceService.getAllConfigs();
    }

    @GetMapping("/options")
    public List<DataSourceOptionDTO> getOptions() {
        return dataSourceService.getAllOptions();
    }

    @PostMapping("/config")
    @RequirePermission("datasource:list")
    public boolean createConfig(@RequestBody DataSourceConfig config) {
        return dataSourceService.save(config);
    }

    @PutMapping("/config/{id}")
    @RequirePermission("datasource:list")
    public boolean updateConfig(@PathVariable Long id, @RequestBody DataSourceConfig config) {
        boolean updated = dataSourceService.updateConfig(id, config);
        if (updated) {
            dynamicDataSourceService.evict(id);
        }
        return updated;
    }

    @DeleteMapping("/config/{id}")
    @RequirePermission("datasource:list")
    public boolean deleteConfig(@PathVariable Long id) {
        boolean removed = dataSourceService.removeById(id);
        if (removed) {
            dynamicDataSourceService.evict(id);
        }
        return removed;
    }
}
