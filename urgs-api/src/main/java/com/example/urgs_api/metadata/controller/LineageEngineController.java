package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.service.LineageEngineService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/metadata/lineage/engine")
@RequiredArgsConstructor
public class LineageEngineController {

    private final LineageEngineService lineageEngineService;

    @GetMapping("/status")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> status() {
        return lineageEngineService.status();
    }

    @PostMapping("/start")
    @RequirePermission("metadata:lineage:engine:start")
    public Map<String, Object> start() {
        return lineageEngineService.start();
    }

    @PostMapping("/stop")
    @RequirePermission("metadata:lineage:engine:stop")
    public Map<String, Object> stop() {
        return lineageEngineService.stop();
    }

    @PostMapping("/restart")
    @RequirePermission("metadata:lineage:engine:restart")
    public Map<String, Object> restart() {
        return lineageEngineService.restart();
    }

    @GetMapping("/logs")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> logs(@RequestParam(defaultValue = "200") int lines) {
        return lineageEngineService.logs(lines);
    }
}
