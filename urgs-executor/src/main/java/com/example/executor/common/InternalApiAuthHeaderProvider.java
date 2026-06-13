package com.example.executor.common;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;

@Component
public class InternalApiAuthHeaderProvider {

    private final String authHeader;
    private final String authPrefix;
    private final String authToken;

    public InternalApiAuthHeaderProvider(
            @Value("${task.api-auth-header:Authorization}") String authHeader,
            @Value("${task.api-auth-prefix:Bearer }") String authPrefix,
            @Value("${task.api-auth-token:}") String authToken) {
        if (!StringUtils.hasText(authHeader) || !StringUtils.hasText(authToken)) {
            throw new IllegalStateException("必须配置 URGS_INTERNAL_API_TOKEN 才能启动 Executor");
        }
        this.authHeader = authHeader;
        this.authPrefix = authPrefix;
        this.authToken = authToken;
    }

    public void apply(HttpHeaders headers) {
        headers.set(authHeader, authPrefix + authToken);
    }
}
