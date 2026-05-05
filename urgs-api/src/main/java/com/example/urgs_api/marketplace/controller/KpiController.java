package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.marketplace.dto.KpiDetailDTO;
import com.example.urgs_api.marketplace.dto.KpiSummaryDTO;
import com.example.urgs_api.marketplace.dto.TeamKpiDTO;
import com.example.urgs_api.marketplace.model.KpiSnapshot;
import com.example.urgs_api.marketplace.service.KpiService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestAttribute;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.time.LocalDate;
import java.time.YearMonth;
import java.util.List;

@RestController
@RequestMapping("/api/marketplace/kpi")
public class KpiController {

    @Autowired
    private KpiService kpiService;

    @GetMapping("/summary")
    public KpiSummaryDTO getMySummary(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(required = false) String userId,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate) {
        String effectiveUserId = userId != null && !userId.isEmpty() ? userId : getEffectiveUserId(headerUserId, attrUserId);
        return kpiService.getUserSummary(effectiveUserId, startDate, endDate);
    }

    @GetMapping("/details")
    public List<KpiDetailDTO> getDetails(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(required = false) String userId,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate) {
        String effectiveUserId = userId != null && !userId.isEmpty() ? userId : getEffectiveUserId(headerUserId, attrUserId);
        return kpiService.getUserDetails(effectiveUserId, startDate, endDate);
    }

    @GetMapping("/team")
    public TeamKpiDTO getTeamKpi(
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate) {
        return kpiService.getTeamKpi(startDate, endDate);
    }

    @GetMapping("/leaderboard")
    public List<KpiSummaryDTO> getLeaderboard(
            @RequestParam(defaultValue = "overall") String dimension,
            @RequestParam(required = false) LocalDate startDate,
            @RequestParam(required = false) LocalDate endDate) {
        return kpiService.getLeaderboard(dimension, startDate, endDate);
    }

    @GetMapping("/snapshots")
    public List<KpiSnapshot> listSnapshots(@RequestParam(required = false) String period) {
        String effectivePeriod = period != null && !period.isEmpty() ? period : YearMonth.now().toString();
        return kpiService.listSnapshots(effectivePeriod);
    }

    @PostMapping("/snapshots/generate")
    public List<KpiSnapshot> generateSnapshot(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(required = false) String period) {
        String effectivePeriod = period != null && !period.isEmpty() ? period : YearMonth.now().toString();
        return kpiService.generateMonthlySnapshot(effectivePeriod, getEffectiveUserId(headerUserId, attrUserId));
    }

    private String getEffectiveUserId(String headerUserId, Long attrUserId) {
        if (headerUserId != null && !headerUserId.isEmpty()) {
            return headerUserId;
        }
        if (attrUserId != null) {
            return String.valueOf(attrUserId);
        }
        throw new IllegalArgumentException("Missing user identifier");
    }
}
