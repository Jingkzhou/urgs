package com.example.urgs_api.auth.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.auth.dto.AuthResponse;
import com.example.urgs_api.auth.dto.LoginRequest;
import com.example.urgs_api.auth.service.AuthTokenService;
import com.example.urgs_api.auth.util.RsaSsoTokenUtil;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final AuthTokenService authTokenService;
    private final com.example.urgs_api.role.service.RoleService roleService;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

    @Value("${urgs.web-base-url:}")
    private String configuredWebBaseUrl;

    @Value("${urgs.inbound-sso.rsa.private-key:}")
    private String inboundSsoRsaPrivateKey;

    public AuthController(UserService userService, AuthTokenService authTokenService,
            com.example.urgs_api.role.service.RoleService roleService,
            org.springframework.security.crypto.password.PasswordEncoder passwordEncoder) {
        this.userService = userService;
        this.authTokenService = authTokenService;
        this.roleService = roleService;
        this.passwordEncoder = passwordEncoder;
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@RequestBody LoginRequest req) {
        if (!StringUtils.hasText(req.getUsername()) || !StringUtils.hasText(req.getPassword())) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).build();
        }
        User user = userService.getOne(new LambdaQueryWrapper<User>().eq(User::getEmpId, req.getUsername()));

        if (user == null || user.getPassword() == null
                || !passwordEncoder.matches(req.getPassword(), user.getPassword())) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        String token = authTokenService.issue(user.getId());

        return ResponseEntity.ok(buildAuthResponse(token, user));
    }

    @GetMapping("/sso/rsa")
    public ResponseEntity<?> rsaSsoRedirect(@RequestParam("ssoToken") String ssoToken,
            @RequestParam(value = "target", required = false) String target) {
        AuthResponse response = authenticateByRsaSsoToken(ssoToken);
        String redirectUrl = resolveWebBaseUrl()
                + "?sso_login_token=" + encode(response.getToken());
        if (StringUtils.hasText(target)) {
            redirectUrl += "&sso_target=" + encode(target);
        }
        return ResponseEntity.status(HttpStatus.FOUND).location(URI.create(redirectUrl)).build();
    }

    @PostMapping("/sso/rsa")
    public ResponseEntity<AuthResponse> rsaSso(@RequestBody java.util.Map<String, String> params) {
        String ssoToken = params == null ? null : params.get("ssoToken");
        return ResponseEntity.ok(authenticateByRsaSsoToken(ssoToken));
    }

    @GetMapping("/profile")
    public ResponseEntity<AuthResponse> profile(
            @RequestHeader(value = "Authorization", required = false) String authorization,
            @RequestParam(value = "token", required = false) String tokenParam) {
        String token = extractToken(authorization, tokenParam);
        if (!StringUtils.hasText(token)) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        Long userId = authTokenService.validate(token);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        return ResponseEntity.ok(buildAuthResponse(token, user));
    }

    private AuthResponse authenticateByRsaSsoToken(String ssoToken) {
        String empId;
        try {
            empId = RsaSsoTokenUtil.decryptFromBase64(ssoToken, inboundSsoRsaPrivateKey);
        } catch (IllegalArgumentException e) {
            HttpStatus status = StringUtils.hasText(inboundSsoRsaPrivateKey) ? HttpStatus.BAD_REQUEST
                    : HttpStatus.SERVICE_UNAVAILABLE;
            throw new org.springframework.web.server.ResponseStatusException(status, e.getMessage(), e);
        }
        User user = userService.getOne(new LambdaQueryWrapper<User>().eq(User::getEmpId, empId));
        if (user == null) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.UNAUTHORIZED, "SSO 用户不存在");
        }
        if ("inactive".equalsIgnoreCase(user.getStatus())) {
            throw new org.springframework.web.server.ResponseStatusException(HttpStatus.FORBIDDEN, "SSO 用户已停用");
        }
        String token = authTokenService.issue(user.getId());
        return buildAuthResponse(token, user);
    }

    private AuthResponse buildAuthResponse(String token, User user) {
        Long roleId = user.getRoleId();
        if (roleId == null && StringUtils.hasText(user.getRoleName())) {
            com.example.urgs_api.role.model.Role role = roleService.getOne(
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.example.urgs_api.role.model.Role>()
                            .eq(com.example.urgs_api.role.model.Role::getName, user.getRoleName())
                            .or()
                            .eq(com.example.urgs_api.role.model.Role::getCode, user.getRoleName()));
            if (role != null) {
                roleId = role.getId();
            }
        }

        return new AuthResponse(token, String.valueOf(user.getId()), user.getEmpId(), user.getName(),
                user.getRoleName(), roleId, user.getSystem(), user.getOrgName(), user.getPhone(),
                user.getAvatarUrl());
    }

    private String extractToken(String authorization, String tokenParam) {
        if (StringUtils.hasText(tokenParam))
            return tokenParam;
        if (StringUtils.hasText(authorization) && authorization.startsWith("Bearer ")) {
            return authorization.substring("Bearer ".length());
        }
        return null;
    }

    private String resolveWebBaseUrl() {
        if (StringUtils.hasText(configuredWebBaseUrl)) {
            return configuredWebBaseUrl.endsWith("/") ? configuredWebBaseUrl.substring(0, configuredWebBaseUrl.length() - 1)
                    : configuredWebBaseUrl;
        }
        return "/";
    }

    private String encode(String value) {
        return URLEncoder.encode(value, StandardCharsets.UTF_8);
    }
}
