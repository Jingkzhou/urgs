package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.metadata.service.LineageEngineService;
import com.example.urgs_api.metadata.service.LineageService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/metadata/lineage/engine")
@RequiredArgsConstructor
public class LineageEngineController {

    private final LineageEngineService lineageEngineService;
    private final LineageService lineageService;

    @GetMapping("/status")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> status() {
        return lineageEngineService.status();
    }

    @PostMapping(value = "/start", consumes = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("metadata:lineage:engine:start")
    public Map<String, Object> start(@RequestBody(required = false) StartEngineRequest request) {
        return lineageEngineService.start(request);
    }

    @PostMapping(value = "/start", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @RequirePermission("metadata:lineage:engine:start")
    public Map<String, Object> startWithUpload(
            @RequestParam("files") List<MultipartFile> files,
            @RequestParam(value = "user", required = false) String user,
            @RequestParam(value = "language", required = false) String language) {
        return lineageEngineService.startWithUpload(files, user, language);
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
    public Map<String, Object> logs(@RequestParam(value = "lines", defaultValue = "200") int lines,
            @RequestParam(value = "recordId", required = false) String recordId) {
        return lineageEngineService.logs(lines, recordId);
    }

    @GetMapping("/version-check")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> checkVersion(@RequestParam("repoId") Long repoId,
            @RequestParam(value = "ref", required = false) String ref) {
        return lineageEngineService.checkVersionConsistency(repoId, ref);
    }

    @PostMapping("/clear-database")
    @RequirePermission("metadata:lineage:engine:stop")
    public Map<String, Object> clearDatabase() {
        return lineageService.clearAll();
    }
}
