package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.dto.AppBranchStatsVO;
import com.example.urgs_api.version.dto.AppEnvironmentMatrixVO;
import com.example.urgs_api.version.service.AppSystemVersionService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/app")
@RequiredArgsConstructor
public class AppSystemVersionController {

    private final AppSystemVersionService service;

    @GetMapping("/{systemId}/matrix")
    public ResponseEntity<List<AppEnvironmentMatrixVO>> getEnvironmentMatrix(@PathVariable Long systemId) {
        return ResponseEntity.ok(service.getEnvironmentMatrix(systemId));
    }

    @GetMapping("/{systemId}/branches")
    public ResponseEntity<List<AppBranchStatsVO>> getBranchGovernance(@PathVariable Long systemId) {
        return ResponseEntity.ok(service.getBranchGovernance(systemId));
    }
}
