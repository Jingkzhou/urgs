package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.InfrastructureAsset;
import com.example.urgs_api.version.service.InfrastructureService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/infrastructure")
@RequiredArgsConstructor
public class InfrastructureController {

    private final InfrastructureService infrastructureService;

    @GetMapping
    public List<InfrastructureAsset> list(
            @RequestParam(required = false) Long appSystemId,
            @RequestParam(required = false) Long envId,
            @RequestParam(required = false) String envType) {
        return infrastructureService.findByFilter(appSystemId, envId, envType);
    }

    @GetMapping("/{id}")
    public ResponseEntity<InfrastructureAsset> getById(@PathVariable Long id) {
        return infrastructureService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public InfrastructureAsset create(@RequestBody InfrastructureAsset asset) {
        return infrastructureService.save(asset);
    }

    @PutMapping("/{id}")
    public InfrastructureAsset update(@PathVariable Long id, @RequestBody InfrastructureAsset asset) {
        return infrastructureService.update(id, asset);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        infrastructureService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/export")
    public void export(jakarta.servlet.http.HttpServletResponse response) throws java.io.IOException {
        infrastructureService.exportData(response);
    }

    @PostMapping("/import")
    public ResponseEntity<Void> importData(@RequestParam("file") org.springframework.web.multipart.MultipartFile file)
            throws java.io.IOException {
        infrastructureService.importData(file);
        return ResponseEntity.ok().build();
    }
}
