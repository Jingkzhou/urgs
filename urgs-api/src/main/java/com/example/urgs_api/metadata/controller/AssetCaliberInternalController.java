package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.dto.AssetCaliberDTO.ApplyResult;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.CaliberChangeRequest;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.PreviewResponse;
import com.example.urgs_api.metadata.dto.AssetCaliberDTO.RegTableContext;
import com.example.urgs_api.metadata.service.AssetCaliberService;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/internal/asset-caliber")
public class AssetCaliberInternalController {

    private final AssetCaliberService assetCaliberService;

    public AssetCaliberInternalController(AssetCaliberService assetCaliberService) {
        this.assetCaliberService = assetCaliberService;
    }

    @GetMapping("/tables/resolve")
    public RegTableContext resolveTable(
            @RequestParam Long requesterUserId,
            @RequestParam String systemCode,
            @RequestParam String tableName) {
        return assetCaliberService.resolveTable(requesterUserId, systemCode, tableName);
    }

    @GetMapping("/tables/{tableId}")
    public RegTableContext getTable(
            @PathVariable Long tableId,
            @RequestParam Long requesterUserId) {
        return assetCaliberService.getTable(requesterUserId, tableId);
    }

    @PostMapping("/preview")
    public PreviewResponse preview(@RequestBody CaliberChangeRequest request) {
        return assetCaliberService.preview(request);
    }

    @PostMapping("/apply")
    public ApplyResult apply(@RequestBody CaliberChangeRequest request) {
        return assetCaliberService.apply(request);
    }
}
