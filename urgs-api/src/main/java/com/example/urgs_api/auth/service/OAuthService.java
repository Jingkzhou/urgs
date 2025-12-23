package com.example.urgs_api.auth.service;

public interface OAuthService {
    String createCode(Long userId);

    Long consumeCode(String code);
}
