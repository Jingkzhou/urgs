package com.example.urgs_api.auth.service.impl;

import com.example.urgs_api.auth.service.OAuthService;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OAuthServiceImpl implements OAuthService {

    // In-memory store for demo. Use Redis in production.
    private final Map<String, Long> codeStore = new ConcurrentHashMap<>();

    @Override
    public String createCode(Long userId) {
        String code = UUID.randomUUID().toString();
        codeStore.put(code, userId);
        return code;
    }

    @Override
    public Long consumeCode(String code) {
        return codeStore.remove(code);
    }
}
