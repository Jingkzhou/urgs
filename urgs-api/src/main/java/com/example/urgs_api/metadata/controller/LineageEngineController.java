package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.dto.StartEngineRequest;
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
    public Map<String, Object> start(@RequestBody(required = false) StartEngineRequest request) {
        return lineageEngineService.start(request);
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
    public Map<String, Object> logs(@RequestParam(defaultValue = "200") int lines,
            @RequestParam(required = false) String recordId) {
        return lineageEngineService.logs(lines, recordId);
    }

    @GetMapping("/version-check")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> checkVersion(@RequestParam Long repoId, @RequestParam(required = false) String ref) {
        return lineageEngineService.checkVersionConsistency(repoId, ref);
    }
}
