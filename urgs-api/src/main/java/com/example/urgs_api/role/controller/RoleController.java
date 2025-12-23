package com.example.urgs_api.role.controller;

import com.example.urgs_api.role.dto.RoleDTO;
import com.example.urgs_api.role.dto.RoleRequest;
import com.example.urgs_api.role.dto.RolePermissionRequest;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/roles")
public class RoleController {

    private final RoleService roleService;

    public RoleController(RoleService roleService) {
        this.roleService = roleService;
    }

    @GetMapping
    public List<RoleDTO> list() {
        return roleService.list().stream().map(RoleDTO::fromEntity).collect(Collectors.toList());
    }

    @PostMapping
    public RoleDTO create(@RequestBody RoleRequest req) {
        Role role = toEntity(req, null);
        roleService.save(role);
        return RoleDTO.fromEntity(role);
    }

    @PutMapping("/{id}")
    public ResponseEntity<RoleDTO> update(@PathVariable("id") Long id, @RequestBody RoleRequest req) {
        Role existing = roleService.getById(id);
        if (existing == null) {
            return ResponseEntity.notFound().build();
        }
        Role role = toEntity(req, id);
        roleService.updateById(role);
        return ResponseEntity.ok(RoleDTO.fromEntity(roleService.getById(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        boolean removed = roleService.removeById(id);
        return removed ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @GetMapping("/{id}/permissions")
    public ResponseEntity<Set<String>> listPermissions(@PathVariable("id") Long id) {
        if (roleService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        Set<String> permissions = roleService.getRolePermissions(id);
        return ResponseEntity.ok(permissions);
    }

    @PutMapping("/{id}/permissions")
    public ResponseEntity<Void> savePermissions(@PathVariable("id") Long id,
            @RequestBody(required = false) RolePermissionRequest req) {
        if (roleService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        List<String> permsList = (req == null || req.getPermissions() == null) ? List.of() : req.getPermissions();
        Set<String> permsSet = new HashSet<>(permsList);
        roleService.updateRolePermissions(id, permsSet);
        return ResponseEntity.noContent().build();
    }

    private Role toEntity(RoleRequest req, Long id) {
        Role role = new Role();
        if (id != null) {
            role.setId(id);
        }
        role.setName(req.getName());
        role.setCode(req.getCode());
        role.setPermission(req.getPermission());
        role.setStatus(req.getStatus());
        role.setRemark(req.getDesc());
        role.setUserCount(req.getCount() == null ? 0 : req.getCount());
        return role;
    }
}
