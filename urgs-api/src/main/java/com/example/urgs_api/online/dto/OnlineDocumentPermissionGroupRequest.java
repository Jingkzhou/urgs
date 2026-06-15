package com.example.urgs_api.online.dto;

import lombok.Data;

import java.util.List;

@Data
public class OnlineDocumentPermissionGroupRequest {
    private String name;
    private String description;
    private List<Long> userIds;
}
