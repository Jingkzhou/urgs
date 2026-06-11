package com.example.urgs_api.ops.controller;

import com.example.urgs_api.ops.entity.InfrastructureSystemManual;
import com.example.urgs_api.ops.service.InfrastructureSystemManualService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/ops/infrastructure/manuals")
@RequiredArgsConstructor
public class InfrastructureSystemManualController {

    private final InfrastructureSystemManualService manualService;

    @GetMapping
    public List<InfrastructureSystemManual> list(
            @RequestParam(required = false) Long appSystemId,
            @RequestParam(required = false) String keyword) {
        return manualService.findByFilter(appSystemId, keyword);
    }

    @PostMapping
    public InfrastructureSystemManual create(@RequestBody InfrastructureSystemManual manual) {
        return manualService.save(manual);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        manualService.delete(id);
        return ResponseEntity.noContent().build();
    }
}
