package com.example.urgs_api.permission.dto;

import java.util.List;

public class PermissionSyncRequest {
    private List<PermissionDTO> items;

    public List<PermissionDTO> getItems() {
        return items;
    }

    public void setItems(List<PermissionDTO> items) {
        this.items = items;
    }
}
