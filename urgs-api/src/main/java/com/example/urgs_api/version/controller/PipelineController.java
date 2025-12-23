package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.Pipeline;
import com.example.urgs_api.version.entity.PipelineRun;
import com.example.urgs_api.version.service.PipelineService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/version/pipelines")
@RequiredArgsConstructor
public class PipelineController {

    private final PipelineService pipelineService;

    // ========== Pipeline CRUD ==========

    @GetMapping
    public List<Pipeline> list(@RequestParam(required = false) Long ssoId,
            @RequestParam(required = false) Long repoId) {
        if (ssoId != null) {
            return pipelineService.findBySsoId(ssoId);
        }
        if (repoId != null) {
            return pipelineService.findByRepoId(repoId);
        }
        return pipelineService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<Pipeline> getById(@PathVariable Long id) {
        return pipelineService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public Pipeline create(@RequestBody Pipeline pipeline) {
        return pipelineService.create(pipeline);
    }

    @PutMapping("/{id}")
    public Pipeline update(@PathVariable Long id, @RequestBody Pipeline pipeline) {
        return pipelineService.update(id, pipeline);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        pipelineService.delete(id);
        return ResponseEntity.noContent().build();
    }

    // ========== Pipeline Run ==========

    @GetMapping("/{id}/runs")
    public List<PipelineRun> getRuns(@PathVariable Long id) {
        return pipelineService.findRunsByPipelineId(id);
    }

    @GetMapping("/runs/{runId}")
    public ResponseEntity<PipelineRun> getRunById(@PathVariable Long runId) {
        return pipelineService.findRunById(runId)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    /**
     * 触发流水线执行
     */
    @PostMapping("/{id}/trigger")
    public PipelineRun trigger(@PathVariable Long id, @RequestBody(required = false) Map<String, String> params) {
        String branch = params != null ? params.get("branch") : null;
        String triggerType = params != null ? params.get("triggerType") : "manual";
        return pipelineService.trigger(id, branch, triggerType);
    }

    /**
     * 取消执行
     */
    @PostMapping("/runs/{runId}/cancel")
    public ResponseEntity<Void> cancelRun(@PathVariable Long runId) {
        pipelineService.cancelRun(runId);
        return ResponseEntity.ok().build();
    }
}
