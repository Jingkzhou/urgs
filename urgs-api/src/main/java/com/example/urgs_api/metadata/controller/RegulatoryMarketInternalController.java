package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CodeTableContext;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CatalogScanRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.CatalogScanResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.DevelopmentContextRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.DevelopmentContextResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.ElementContext;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.RelationshipRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.RelationshipResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SearchResponse;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SqlValidationRequest;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.SqlValidationResult;
import com.example.urgs_api.metadata.dto.RegulatoryMarketContextDTO.TableContext;
import com.example.urgs_api.metadata.service.RegulatoryMarketContextService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/regulatory-market")
public class RegulatoryMarketInternalController {

    private final RegulatoryMarketContextService contextService;

    public RegulatoryMarketInternalController(RegulatoryMarketContextService contextService) {
        this.contextService = contextService;
    }

    @GetMapping("/search")
    public SearchResponse search(
            @RequestParam(defaultValue = "") String keyword,
            @RequestParam(required = false) String systemCode,
            @RequestParam String allowedSystems,
            @RequestParam(defaultValue = "20") int limit) {
        return contextService.search(keyword, systemCode, allowedSystems, limit);
    }

    @PostMapping("/catalog-scan")
    public CatalogScanResponse scanCatalog(@RequestBody CatalogScanRequest request) {
        return contextService.scanCatalog(request);
    }

    @GetMapping("/tables/{tableId}")
    public TableContext getTable(
            @PathVariable Long tableId,
            @RequestParam String allowedSystems,
            @RequestParam(defaultValue = "100") int elementLimit) {
        return contextService.getTable(tableId, allowedSystems, elementLimit);
    }

    @GetMapping("/elements/{elementId}")
    public ElementContext getElement(
            @PathVariable Long elementId,
            @RequestParam String allowedSystems) {
        return contextService.getElement(elementId, allowedSystems);
    }

    @GetMapping("/code-tables/{tableCode}/values")
    public CodeTableContext getCodeValues(
            @PathVariable String tableCode,
            @RequestParam String allowedSystems,
            @RequestParam(defaultValue = "200") int limit) {
        return contextService.getCodeValues(tableCode, allowedSystems, limit);
    }

    @PostMapping("/relationships")
    public RelationshipResponse getRelationships(@RequestBody RelationshipRequest request) {
        return contextService.getRelationships(request);
    }

    @PostMapping("/development-context")
    public DevelopmentContextResponse buildDevelopmentContext(@RequestBody DevelopmentContextRequest request) {
        return contextService.buildDevelopmentContext(request);
    }

    @PostMapping("/validate-sql")
    public SqlValidationResult validateSql(@RequestBody SqlValidationRequest request) {
        return contextService.validateSql(request);
    }
}
