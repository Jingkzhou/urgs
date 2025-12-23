package com.example.urgs_api.permission.controller;

import com.example.urgs_api.permission.dto.PermissionDiffResponse;
import com.example.urgs_api.permission.dto.PermissionSyncRequest;
import com.example.urgs_api.permission.service.PermissionService;
import com.example.urgs_api.permission.support.PermissionSeedProvider;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

@RestController
@RequestMapping("/api/permissions")
public class PermissionController {

    private final PermissionService permissionService;
    private final PermissionSeedProvider seedProvider;

    public PermissionController(PermissionService permissionService, PermissionSeedProvider seedProvider) {
        this.permissionService = permissionService;
        this.seedProvider = seedProvider;
    }

    @GetMapping
    public List<com.example.urgs_api.permission.dto.PermissionDTO> list() {
        return permissionService.listAll();
    }

    @PostMapping("/diff")
    public PermissionDiffResponse diff(@RequestBody(required = false) PermissionSyncRequest request) {
        List<com.example.urgs_api.permission.dto.PermissionDTO> baseline = (request != null
                && request.getItems() != null) ? request.getItems() : seedProvider.seeds();
        return permissionService.diffAgainst(baseline);
    }

    @PostMapping("/sync")
    public void sync(@RequestBody PermissionSyncRequest request) {
        if (request != null && request.getItems() != null) {
            permissionService.sync(request.getItems());
        }
    }
}
