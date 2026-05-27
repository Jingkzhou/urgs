package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.metadata.service.LineageEngineService;
import com.example.urgs_api.metadata.service.LineageService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.MediaType;
import org.springframework.web.multipart.MultipartFile;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/metadata/lineage/engine")
@RequiredArgsConstructor
@Slf4j
public class LineageEngineController {

    private final LineageEngineService lineageEngineService;
    private final LineageService lineageService;

    @GetMapping("/status")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> status() {
        log.info("[LineageEngineController] status request received");
        return lineageEngineService.status();
    }

    @PostMapping(value = "/start", consumes = MediaType.APPLICATION_JSON_VALUE)
    @RequirePermission("metadata:lineage:engine:start")
    public Map<String, Object> start(@RequestBody(required = false) StartEngineRequest request) {
        log.info("[LineageEngineController] start(json) request received: {}", summarizeStartRequest(request));
        return lineageEngineService.start(request);
    }

    @PostMapping(value = "/start", consumes = MediaType.MULTIPART_FORM_DATA_VALUE)
    @RequirePermission("metadata:lineage:engine:start")
    public Map<String, Object> startWithUpload(
            @RequestParam("files") List<MultipartFile> files,
            @RequestParam(value = "user", required = false) String user,
            @RequestParam(value = "language", required = false) String language,
            @RequestParam(value = "physicalDataSourceId", required = false) Long physicalDataSourceId,
            @RequestParam(value = "enableAiReview", required = false) Boolean enableAiReview) {
        log.info("[LineageEngineController] start(upload) request received: fileCount={}, fileNames={}, user={}, language={}, physicalDataSourceId={}, enableAiReview={}",
                files != null ? files.size() : 0,
                files != null ? files.stream().map(MultipartFile::getOriginalFilename).toList() : List.of(),
                user,
                language,
                physicalDataSourceId,
                enableAiReview);
        return lineageEngineService.startWithUpload(files, user, language, physicalDataSourceId, enableAiReview);
    }

    @PostMapping("/stop")
    @RequirePermission("metadata:lineage:engine:stop")
    public Map<String, Object> stop() {
        log.info("[LineageEngineController] stop request received");
        return lineageEngineService.stop();
    }

    @PostMapping("/restart")
    @RequirePermission("metadata:lineage:engine:restart")
    public Map<String, Object> restart() {
        log.info("[LineageEngineController] restart request received");
        return lineageEngineService.restart();
    }

    @GetMapping("/logs")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> logs(@RequestParam(value = "lines", defaultValue = "200") int lines,
            @RequestParam(value = "recordId", required = false) String recordId) {
        log.info("[LineageEngineController] logs request received: lines={}, recordId={}", lines, recordId);
        return lineageEngineService.logs(lines, recordId);
    }

    @GetMapping("/version-check")
    @RequirePermission("metadata:lineage:engine:logs")
    public Map<String, Object> checkVersion(@RequestParam("repoId") Long repoId,
            @RequestParam(value = "ref", required = false) String ref) {
        log.info("[LineageEngineController] version-check request received: repoId={}, ref={}", repoId, ref);
        return lineageEngineService.checkVersionConsistency(repoId, ref);
    }

    @PostMapping("/clear-database")
    @RequirePermission("metadata:lineage:engine:stop")
    public Map<String, Object> clearDatabase() {
        log.info("[LineageEngineController] clear-database request received");
        return lineageService.clearAll();
    }

    private String summarizeStartRequest(StartEngineRequest request) {
        if (request == null) {
            return "null";
        }
        return "sourceType=" + request.getSourceType()
                + ", repoId=" + request.getRepoId()
                + ", ref=" + request.getRef()
                + ", pathCount=" + (request.getPaths() != null ? request.getPaths().size() : 0)
                + ", paths=" + request.getPaths()
                + ", user=" + request.getUser()
                + ", language=" + request.getLanguage()
                + ", physicalDataSourceId=" + request.getPhysicalDataSourceId()
                + ", localPath=" + request.getLocalPath()
                + ", enableAiReview=" + request.getEnableAiReview();
    }
}
