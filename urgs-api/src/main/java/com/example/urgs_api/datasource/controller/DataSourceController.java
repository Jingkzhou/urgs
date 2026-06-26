package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.datasource.dto.DataSourceOptionDTO;
import com.example.urgs_api.datasource.dto.DataSourcePoolDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.service.DataSourcePoolService;
import com.example.urgs_api.datasource.service.DataSourceService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@Slf4j
@RestController
@RequestMapping("/api/datasource")
public class DataSourceController {

    private final DataSourceService dataSourceService;
    private final DataSourcePoolService dataSourcePoolService;
    private final com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService;

    public DataSourceController(DataSourceService dataSourceService,
            DataSourcePoolService dataSourcePoolService,
            com.example.urgs_api.datasource.service.DynamicDataSourceService dynamicDataSourceService) {
        this.dataSourceService = dataSourceService;
        this.dataSourcePoolService = dataSourcePoolService;
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

    @GetMapping("/pool")
    @RequirePermission("datasource:list")
    public List<DataSourcePoolDTO> getPools() {
        return dataSourcePoolService.listPools();
    }

    @GetMapping("/pool/options")
    public List<DataSourcePoolDTO> getPoolOptions() {
        return dataSourcePoolService.listPools();
    }

    @PostMapping("/pool")
    @RequirePermission("datasource:list")
    public boolean createPool(@RequestBody DataSourcePoolDTO pool) {
        return dataSourcePoolService.savePool(pool);
    }

    @PutMapping("/pool/{id}")
    @RequirePermission("datasource:list")
    public boolean updatePool(@PathVariable Long id, @RequestBody DataSourcePoolDTO pool) {
        pool.setId(id);
        return dataSourcePoolService.savePool(pool);
    }

    @DeleteMapping("/pool/{id}")
    @RequirePermission("datasource:list")
    public boolean deletePool(@PathVariable Long id) {
        return dataSourcePoolService.deletePool(id);
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
