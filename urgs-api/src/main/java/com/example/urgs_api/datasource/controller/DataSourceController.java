package com.example.urgs_api.datasource.controller;

import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.service.DataSourceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/datasource")
public class DataSourceController {

    @Autowired
    private DataSourceService dataSourceService;

    @GetMapping("/meta")
    public List<DataSourceMeta> getMeta() {
        return dataSourceService.getAllMeta();
    }

    @GetMapping("/config")
    public List<DataSourceConfig> getConfigs() {
        return dataSourceService.getAllConfigs();
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
