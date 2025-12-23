package com.example.urgs_api.auth.service;

import org.springframework.stereotype.Service;

import java.time.Instant;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class AuthTokenService {

    private static class Session {
        final Long userId;
        final Instant expiresAt;

        Session(Long userId, Instant expiresAt) {
            this.userId = userId;
            this.expiresAt = expiresAt;
        }
    }

    private final Map<String, Session> sessions = new ConcurrentHashMap<>();
    private static final long TTL_SECONDS = 2 * 60 * 60; // 2 hours

    public String issue(Long userId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        sessions.put(token, new Session(userId, Instant.now().plusSeconds(TTL_SECONDS)));
        return token;
    }

    public Long validate(String token) {
        Session s = sessions.get(token);
        if (s == null) return null;
        if (Instant.now().isAfter(s.expiresAt)) {
            sessions.remove(token);
            return null;
        }
        return s.userId;
    }
}
