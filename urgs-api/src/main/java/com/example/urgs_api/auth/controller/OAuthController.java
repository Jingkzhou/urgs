package com.example.urgs_api.auth.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.auth.service.AuthTokenService;
import com.example.urgs_api.auth.service.OAuthService;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/oauth")
public class OAuthController {

    private final SysSystemService sysSystemService;
    private final AuthTokenService authTokenService;
    private final OAuthService oAuthService;
    private final UserService userService;

    @Value("${urgs.web-base-url:}")
    private String configuredWebBaseUrl;

    public OAuthController(SysSystemService sysSystemService, AuthTokenService authTokenService,
            OAuthService oAuthService,
            UserService userService) {
        this.sysSystemService = sysSystemService;
        this.authTokenService = authTokenService;
        this.oAuthService = oAuthService;
        this.userService = userService;
    }

    @GetMapping("/authorize")
    public ResponseEntity<?> authorizeRedirect(@RequestParam("client_id") String clientId,
            @RequestParam("redirect_uri") String redirectUri,
            @RequestParam(value = "response_type", defaultValue = "code") String responseType,
            @RequestParam(value = "state", required = false) String state,
            HttpServletRequest request) {
        if (!"code".equals(responseType)) {
            return ResponseEntity.badRequest().body("Unsupported response_type");
        }

        SysSystem client = sysSystemService
                .getOne(new LambdaQueryWrapper<SysSystem>().eq(SysSystem::getClientId, clientId.trim()));
        if (client == null) {
            return ResponseEntity.badRequest().body("Invalid client_id");
        }
        if (!isValidRedirectUri(client, redirectUri)) {
            return ResponseEntity.badRequest().body("Invalid redirect_uri");
        }

        String loginUrl = resolveWebBaseUrl(request)
                + "?client_id=" + encode(clientId.trim())
                + "&redirect_uri=" + encode(redirectUri);
        if (state != null && !state.isBlank()) {
            loginUrl += "&state=" + encode(state);
        }
        return ResponseEntity.status(HttpStatus.FOUND).location(URI.create(loginUrl)).build();
    }

    @PostMapping("/authorize")
    public ResponseEntity<?> authorize(@RequestBody Map<String, String> params, HttpServletRequest request) {
        String clientId = params.get("client_id") == null ? null : params.get("client_id").trim();
        String redirectUri = params.get("redirect_uri");
        String responseType = params.get("response_type");

        if (!"code".equals(responseType)) {
            return ResponseEntity.badRequest().body("Unsupported response_type");
        }

        SysSystem client = sysSystemService
                .getOne(new LambdaQueryWrapper<SysSystem>().eq(SysSystem::getClientId, clientId));
        if (client == null) {
            return ResponseEntity.badRequest().body("Invalid client_id");
        }

        // Simple validation: redirect_uri must match configured callbackUrl
        if (!isValidRedirectUri(client, redirectUri)) {
            return ResponseEntity.badRequest().body("Invalid redirect_uri");
        }

        // Get current user ID from request (set by AuthenticationInterceptor)
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        String code = oAuthService.createCode(userId);

        Map<String, String> result = new LinkedHashMap<>();
        result.put("code", code);
        result.put("redirect_uri", redirectUri);
        if (params.get("state") != null) {
            result.put("state", params.get("state"));
        }
        return ResponseEntity.ok(result);
    }

    @PostMapping("/token")
    public ResponseEntity<?> token(@RequestBody Map<String, String> params) {
        String grantType = params.get("grant_type");
        String code = params.get("code");
        // clientId/secret validation omitted for demo simplicity

        if (!"authorization_code".equals(grantType)) {
            return ResponseEntity.badRequest().body("Unsupported grant_type");
        }

        Long userId = oAuthService.consumeCode(code);
        if (userId == null) {
            return ResponseEntity.badRequest().body("Invalid or expired code");
        }

        String token = authTokenService.issue(userId);
        return ResponseEntity.ok(Map.of(
                "access_token", token,
                "token_type", "Bearer",
                "expires_in", 7200));
    }

    @GetMapping("/user_info")
    public ResponseEntity<?> userInfo(HttpServletRequest request) {
        Long userId = (Long) request.getAttribute("userId");
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }

        return ResponseEntity.ok(Map.of(
                "id", user.getId(),
                "empId", user.getEmpId(),
                "name", user.getName(),
                "orgName", user.getOrgName(),
                "roleName", user.getRoleName()));
    }

    private boolean isValidRedirectUri(SysSystem client, String redirectUri) {
        if (redirectUri == null || client.getCallbackUrl() == null) {
            return false;
        }
        return client.getCallbackUrl().equals(redirectUri) || redirectUri.startsWith(client.getCallbackUrl());
    }

    private String resolveWebBaseUrl(HttpServletRequest request) {
        if (configuredWebBaseUrl != null && !configuredWebBaseUrl.isBlank()) {
            return trimTrailingSlash(configuredWebBaseUrl);
        }
        return request.getScheme() + "://" + request.getServerName() + ":3000/";
    }

    private String trimTrailingSlash(String value) {
        return value.endsWith("/") ? value : value + "/";
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
