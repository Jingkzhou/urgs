package com.example.urgs_api.role.dto;

import java.util.ArrayList;
import java.util.List;

public class RolePermissionRequest {
    private List<String> permissions = new ArrayList<>();

    public List<String> getPermissions() {
        return permissions;
    }

    public void setPermissions(List<String> permissions) {
        this.permissions = permissions;
    }
}
