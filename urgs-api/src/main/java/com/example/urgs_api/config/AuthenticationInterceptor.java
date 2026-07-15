package com.example.urgs_api.config;

import com.example.urgs_api.auth.service.AuthTokenService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Component;
import org.springframework.util.StringUtils;
import org.springframework.web.servlet.HandlerInterceptor;
import lombok.extern.slf4j.Slf4j;

@Slf4j
@Component
public class AuthenticationInterceptor implements HandlerInterceptor {

    private final AuthTokenService authTokenService;

    public AuthenticationInterceptor(AuthTokenService authTokenService) {
        this.authTokenService = authTokenService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler)
            throws Exception {
        if ("OPTIONS".equalsIgnoreCase(request.getMethod())) {
            return true;
        }
        if ("GET".equalsIgnoreCase(request.getMethod()) && "/api/oauth/authorize".equals(request.getRequestURI())) {
            return true;
        }
        if ("POST".equalsIgnoreCase(request.getMethod()) && "/api/oauth/token".equals(request.getRequestURI())) {
            return true;
        }

        String token = extractToken(request);
        if (!StringUtils.hasText(token)) {
            log.warn("[AUTH-GATE] rejected reason=token_missing, method={}, uri={}, remoteAddr={}",
                    request.getMethod(), request.getRequestURI(), request.getRemoteAddr());
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return false;
        }

        Long userId = authTokenService.validate(token);
        if (userId == null) {
            log.warn("[AUTH-GATE] rejected reason=token_invalid, method={}, uri={}, tokenRef={}, remoteAddr={}",
                    request.getMethod(), request.getRequestURI(), ref(token), request.getRemoteAddr());
            response.setStatus(HttpStatus.UNAUTHORIZED.value());
            return false;
        }

        log.debug("[AUTH-GATE] accepted method={}, uri={}, userId={}, tokenRef={}",
                request.getMethod(), request.getRequestURI(), userId, ref(token));
        request.setAttribute("userId", userId);
        return true;
    }

    private String extractToken(HttpServletRequest request) {
        String bearerToken = request.getHeader("Authorization");
        if (StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
            return bearerToken.substring(7);
        }
        return request.getParameter("token");
    }

    private String ref(String value) {
        return value == null ? "null" : Integer.toHexString(value.hashCode());
    }
}
