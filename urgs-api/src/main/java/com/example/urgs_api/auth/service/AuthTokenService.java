package com.example.urgs_api.auth.service;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;
import lombok.extern.slf4j.Slf4j;

import java.time.Instant;
import java.util.UUID;

@Slf4j
@Service
public class AuthTokenService {

    private static final long TTL_SECONDS = 2 * 60 * 60; // 2 hours
    private final JdbcTemplate jdbcTemplate;

    public AuthTokenService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }

    public String issue(Long userId) {
        String token = UUID.randomUUID().toString().replace("-", "");
        Instant expiresAt = Instant.now().plusSeconds(TTL_SECONDS);
        jdbcTemplate.update("""
                INSERT INTO sys_auth_session (token, user_id, expires_at)
                VALUES (?, ?, ?)
                ON DUPLICATE KEY UPDATE user_id = VALUES(user_id), expires_at = VALUES(expires_at)
                """, token, userId, java.sql.Timestamp.from(expiresAt));
        log.info("[AUTH-SESSION] issued userId={}, tokenRef={}, expiresAt={}", userId, ref(token), expiresAt);
        return token;
    }

    public Long validate(String token) {
        Instant now = Instant.now();
        AuthSession session = jdbcTemplate.query("""
                SELECT user_id, expires_at
                FROM sys_auth_session
                WHERE token = ?
                """, rs -> {
            if (!rs.next()) {
                return null;
            }
            return new AuthSession(rs.getLong("user_id"), rs.getTimestamp("expires_at").toInstant());
        }, token);

        if (session == null) {
            log.warn("[AUTH-SESSION] validation_failed reason=not_found, tokenRef={}", ref(token));
            return null;
        }
        if (now.isAfter(session.expiresAt())) {
            jdbcTemplate.update("DELETE FROM sys_auth_session WHERE token = ?", token);
            log.warn("[AUTH-SESSION] validation_failed reason=expired, userId={}, tokenRef={}, expiredAt={}",
                    session.userId(), ref(token), session.expiresAt());
            return null;
        }

        jdbcTemplate.update("UPDATE sys_auth_session SET expires_at = ? WHERE token = ?",
                java.sql.Timestamp.from(now.plusSeconds(TTL_SECONDS)), token);
        log.debug("[AUTH-SESSION] validated userId={}, tokenRef={}", session.userId(), ref(token));
        return session.userId();
    }

    private String ref(String value) {
        return value == null ? "null" : Integer.toHexString(value.hashCode());
    }

    private record AuthSession(Long userId, Instant expiresAt) {
    }
}
