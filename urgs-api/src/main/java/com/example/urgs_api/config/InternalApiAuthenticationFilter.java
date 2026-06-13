package com.example.urgs_api.config;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.web.util.UriUtils;

import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;

@Component
public class InternalApiAuthenticationFilter extends OncePerRequestFilter {

    private static final String INTERNAL_API_ROOT = "/api/internal";

    private final String authHeader;
    private final String authPrefix;
    private final String authToken;

    public InternalApiAuthenticationFilter(
            @Value("${urgs.internal-api.auth-header:Authorization}") String authHeader,
            @Value("${urgs.internal-api.auth-prefix:Bearer }") String authPrefix,
            @Value("${urgs.internal-api.auth-token:}") String authToken) {
        if (!StringUtils.hasText(authHeader) || !StringUtils.hasText(authToken)) {
            throw new IllegalStateException("必须配置 URGS_INTERNAL_API_TOKEN 才能启动内部 API");
        }
        this.authHeader = authHeader;
        this.authPrefix = authPrefix;
        this.authToken = authToken;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        if (!isInternalApiRequest(request)) {
            filterChain.doFilter(request, response);
            return;
        }

        String providedCredential = request.getHeader(authHeader);
        String expectedCredential = authPrefix + authToken;
        if (!constantTimeEquals(expectedCredential, providedCredential)) {
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return;
        }

        filterChain.doFilter(request, response);
    }

    private boolean isInternalApiPath(String path) {
        return INTERNAL_API_ROOT.equals(path)
                || path.startsWith(INTERNAL_API_ROOT + "/")
                || path.startsWith(INTERNAL_API_ROOT + ";");
    }

    private boolean isInternalApiRequest(HttpServletRequest request) {
        String rawPath = pathWithinApplication(request);
        if (isInternalApiPath(rawPath)) {
            return true;
        }
        try {
            String decodedPath = UriUtils.decode(rawPath, StandardCharsets.UTF_8);
            return isInternalApiPath(decodedPath)
                    || isInternalApiPath(StringUtils.cleanPath(decodedPath));
        } catch (IllegalArgumentException e) {
            return false;
        }
    }

    private String pathWithinApplication(HttpServletRequest request) {
        String requestUri = request.getRequestURI();
        String contextPath = request.getContextPath();
        return contextPath.isEmpty() ? requestUri : requestUri.substring(contextPath.length());
    }

    private boolean constantTimeEquals(String expected, String actual) {
        if (actual == null) {
            return false;
        }
        return MessageDigest.isEqual(
                expected.getBytes(StandardCharsets.UTF_8),
                actual.getBytes(StandardCharsets.UTF_8));
    }
}
