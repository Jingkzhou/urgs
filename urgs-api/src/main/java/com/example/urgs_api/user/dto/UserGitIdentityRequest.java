package com.example.urgs_api.user.dto;

import lombok.Data;

@Data
public class UserGitIdentityRequest {
    private String platform;
    private String gitUsername;
    private String gitEmail;
    private String gitUserId;
}
