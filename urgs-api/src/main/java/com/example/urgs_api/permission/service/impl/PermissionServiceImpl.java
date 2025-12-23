package com.example.urgs_api.permission.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.permission.dto.PermissionDTO;
import com.example.urgs_api.permission.dto.PermissionDiffResponse;
import com.example.urgs_api.permission.mapper.PermissionMapper;
import com.example.urgs_api.permission.model.Permission;
import com.example.urgs_api.permission.service.PermissionService;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Set;
import java.util.function.Function;
import java.util.stream.Collectors;

@Service
public class PermissionServiceImpl extends ServiceImpl<PermissionMapper, Permission> implements PermissionService {

    @Override
    public PermissionDiffResponse diffAgainst(List<PermissionDTO> baseline) {
        List<Permission> dbList = list();
        Map<String, Permission> dbMap = dbList.stream()
                .collect(Collectors.toMap(Permission::getCode, Function.identity(), (a, b) -> a));

        List<PermissionDTO> added = new ArrayList<>();
        List<PermissionDTO> modified = new ArrayList<>();
        List<PermissionDTO> removed = new ArrayList<>();

        Set<String> baselineCodes = new HashSet<>();

        // Check for added and modified
        // Map manifest ID -> Code for parent resolution
        Map<String, String> manifestIdToCode = baseline.stream()
                .collect(Collectors.toMap(PermissionDTO::getId, PermissionDTO::getCode, (a, b) -> a));

        // Check for added and modified
        for (PermissionDTO item : baseline) {
            baselineCodes.add(item.getCode());
            Permission existing = dbMap.get(item.getCode());
            if (existing == null) {
                added.add(item);
            } else {
                // Resolve expected parent ID
                String expectedParentId = null;
                if (item.getParentId() != null && !"root".equals(item.getParentId())) {
                    String parentCode = manifestIdToCode.get(item.getParentId());
                    if (parentCode != null) {
                        Permission parent = dbMap.get(parentCode);
                        if (parent != null) {
                            expectedParentId = String.valueOf(parent.getId());
                        }
                    }
                }

                // Check for modification
                boolean changed = !Objects.equals(existing.getName(), item.getName())
                        || !Objects.equals(existing.getType(), item.getType())
                        || !isPathEquivalent(existing.getPath(), item.getPath())
                        || !Objects.equals(existing.getLevel(), item.getLevel())
                        || !Objects.equals(existing.getParentId(), expectedParentId);

                if (changed) {
                    System.out.println("Diff found for " + item.getCode() + ":");
                    if (!Objects.equals(existing.getName(), item.getName()))
                        System.out.println("  Name: " + existing.getName() + " -> " + item.getName());
                    if (!Objects.equals(existing.getType(), item.getType()))
                        System.out.println("  Type: " + existing.getType() + " -> " + item.getType());
                    if (!isPathEquivalent(existing.getPath(), item.getPath()))
                        System.out.println("  Path: " + existing.getPath() + " -> " + item.getPath());
                    if (!Objects.equals(existing.getLevel(), item.getLevel()))
                        System.out.println("  Level: " + existing.getLevel() + " -> " + item.getLevel());
                    if (!Objects.equals(existing.getParentId(), expectedParentId))
                        System.out.println("  ParentId: " + existing.getParentId() + " -> " + expectedParentId);

                    // Update DTO with resolved parentId for display/sync purposes if needed
                    // But for diff response, we usually return what's in manifest or what's in DB?
                    // The frontend likely expects the manifest version in 'modified' list.
                    modified.add(item);
                }
            }
        }

        // Check for removed
        for (Permission p : dbList) {
            if (!baselineCodes.contains(p.getCode())) {
                removed.add(PermissionDTO.fromEntity(p));
            }
        }

        List<PermissionDTO> current = dbList.stream()
                .map(PermissionDTO::fromEntity)
                .collect(Collectors.toList());

        return new PermissionDiffResponse(added, modified, removed, current);
    }

    private boolean isPathEquivalent(String dbPath, String manifestPath) {
        String p1 = normalizePath(dbPath);
        String p2 = normalizePath(manifestPath);
        return Objects.equals(p1, p2);
    }

    private String normalizePath(String path) {
        if (path == null || "-".equals(path)) {
            return "";
        }
        return path;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void sync(List<PermissionDTO> items) {
        // 1. Upsert all items (ignoring parentId for now)
        Map<String, Permission> dbMap = list().stream()
                .collect(Collectors.toMap(Permission::getCode, Function.identity(), (a, b) -> a));

        List<Permission> toSave = new ArrayList<>();
        for (PermissionDTO item : items) {
            Permission p = dbMap.get(item.getCode());
            if (p == null) {
                p = new Permission();
                p.setCode(item.getCode());
                // Use manifest ID as DB ID
                p.setId(item.getId());
            } else {
                // Ensure ID matches manifest if needed, or just trust code match
                // If we want to enforce ID from manifest:
                // p.setId(item.getId());
            }
            p.setName(item.getName());
            p.setType(item.getType());
            p.setPath(item.getPath());
            p.setLevel(item.getLevel());
            // Don't set parentId yet
            toSave.add(p);
        }

        if (!toSave.isEmpty()) {
            saveOrUpdateBatch(toSave);
        }

        // 2. Resolve hierarchy
        // Re-fetch to get fresh state
        dbMap = list().stream()
                .collect(Collectors.toMap(Permission::getCode, Function.identity(), (a, b) -> a));

        // Map manifest ID -> Code
        Map<String, String> manifestIdToCode = items.stream()
                .collect(Collectors.toMap(PermissionDTO::getId, PermissionDTO::getCode, (a, b) -> a));

        List<Permission> updates = new ArrayList<>();
        for (PermissionDTO item : items) {
            if (item.getParentId() != null && !"root".equals(item.getParentId())) {
                String parentCode = manifestIdToCode.get(item.getParentId());
                if (parentCode != null) {
                    Permission parent = dbMap.get(parentCode);
                    Permission child = dbMap.get(item.getCode());
                    if (parent != null && child != null) {
                        String newParentId = parent.getId();
                        if (!Objects.equals(child.getParentId(), newParentId)) {
                            child.setParentId(newParentId);
                            updates.add(child);
                        }
                    }
                }
            }
        }

        // 3. Delete obsolete permissions (Strict Sync)
        Set<String> activeCodes = items.stream()
                .map(PermissionDTO::getCode)
                .collect(Collectors.toSet());

        List<String> idsToDelete = dbMap.values().stream()
                .filter(p -> !activeCodes.contains(p.getCode()))
                .map(Permission::getId)
                .collect(Collectors.toList());

        if (!idsToDelete.isEmpty()) {
            removeBatchByIds(idsToDelete);
        }

        if (!updates.isEmpty()) {
            updateBatchById(updates);
        }
    }

    @Override
    public List<PermissionDTO> listAll() {
        return list().stream().map(PermissionDTO::fromEntity).collect(Collectors.toList());
    }
}
