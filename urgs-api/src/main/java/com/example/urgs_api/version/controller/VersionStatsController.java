package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.dto.DeveloperKpiVO;
import com.example.urgs_api.version.service.VersionStatsService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/version/stats")
@RequiredArgsConstructor
public class VersionStatsController {

    private final VersionStatsService statsService;

    /**
     * Get Developer KPIs
     */
    @GetMapping("/kpi")
    public ResponseEntity<List<DeveloperKpiVO>> getDeveloperKpis(@RequestParam(required = false) Long systemId) {
        return ResponseEntity.ok(statsService.getDeveloperKpis(systemId));
    }

    /**
     * Get Code Quality Trends (mock data for now)
     */
    @GetMapping("/quality-trend")
    public ResponseEntity<Object> getQualityTrend(@RequestParam(required = false) Long userId) {
        return ResponseEntity.ok(statsService.getQualityTrend(userId));
    }

    /**
     * Get Version Overview Stats
     */
    @GetMapping("/overview")
    public ResponseEntity<com.example.urgs_api.version.dto.VersionOverviewVO> getOverviewStats() {
        return ResponseEntity.ok(statsService.getOverviewStats());
    }
}
