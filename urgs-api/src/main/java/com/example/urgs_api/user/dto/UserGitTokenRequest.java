package com.example.urgs_api.user.dto;

import lombok.Data;

@Data
public class UserGitTokenRequest {
    private String platform;
    private String accessToken;
}
