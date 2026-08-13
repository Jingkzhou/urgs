package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.metadata.dto.AgentRegulatoryAssetSearchResponse;
import com.example.urgs_api.metadata.service.AgentRegulatoryAssetQueryService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/agent/v1/regulatory/assets")
@RequirePermission("metadata:asset:view")
public class AgentRegulatoryAssetController {

    private static final int MAX_TRACE_ID_LENGTH = 160;

    private final AgentRegulatoryAssetQueryService queryService;

    public AgentRegulatoryAssetController(AgentRegulatoryAssetQueryService queryService) {
        this.queryService = queryService;
    }

    @GetMapping("/search")
    public AgentRegulatoryAssetSearchResponse search(
            @RequestParam String keyword,
            @RequestParam(required = false) String systemCode,
            @RequestParam(defaultValue = "10") int limit,
            @RequestHeader(value = "X-Trace-Id", required = false) String traceId,
            HttpServletRequest request) {
        return queryService.search(
                (Long) request.getAttribute("userId"),
                keyword,
                systemCode,
                limit,
                normalizeTraceId(traceId));
    }

    private String normalizeTraceId(String traceId) {
        if (traceId == null || traceId.isBlank()) {
            return UUID.randomUUID().toString();
        }
        String normalized = traceId.trim();
        return normalized.length() <= MAX_TRACE_ID_LENGTH
                ? normalized
                : normalized.substring(0, MAX_TRACE_ID_LENGTH);
    }
}
