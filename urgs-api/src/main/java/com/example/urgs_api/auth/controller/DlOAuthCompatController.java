package com.example.urgs_api.auth.controller;

import com.example.urgs_api.auth.service.AuthTokenService;
import com.example.urgs_api.auth.service.OAuthService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.util.LinkedHashMap;
import java.util.Map;

@RestController
@RequestMapping("/idp/oauth2")
public class DlOAuthCompatController {

    private final OAuthService oAuthService;
    private final AuthTokenService authTokenService;
    private final UserService userService;
    private final ObjectMapper objectMapper;

    public DlOAuthCompatController(OAuthService oAuthService, AuthTokenService authTokenService,
            UserService userService, ObjectMapper objectMapper) {
        this.oAuthService = oAuthService;
        this.authTokenService = authTokenService;
        this.userService = userService;
        this.objectMapper = objectMapper;
    }

    @RequestMapping(value = "/getToken", method = { RequestMethod.GET, RequestMethod.POST })
    public ResponseEntity<?> getToken(@RequestBody(required = false) String body,
            HttpServletRequest request) {
        Map<String, String> params = mergeParams(body, request);
        String grantType = params.getOrDefault("grant_type", "authorization_code");
        String code = firstNonBlank(params.get("code"), params.get("auth_code"), params.get("authCode"));

        if (!"authorization_code".equals(grantType)) {
            return ResponseEntity.badRequest().body("Unsupported grant_type");
        }

        Long userId = oAuthService.consumeCode(code);
        if (userId == null) {
            return ResponseEntity.badRequest().body("Invalid or expired code");
        }

        String token = authTokenService.issue(userId);
        Map<String, Object> result = new LinkedHashMap<>();
        result.put("access_token", token);
        result.put("accessToken", token);
        result.put("token_type", "Bearer");
        result.put("tokenType", "Bearer");
        result.put("expires_in", 7200);
        result.put("expiresIn", 7200);
        return ResponseEntity.ok(result);
    }

    @RequestMapping(value = "/getUserInfo", method = { RequestMethod.GET, RequestMethod.POST })
    public ResponseEntity<?> getUserInfo(@RequestBody(required = false) String body,
            HttpServletRequest request) {
        Map<String, String> params = mergeParams(body, request);
        String token = firstNonBlank(params.get("access_token"), params.get("accessToken"), params.get("token"));
        if (token == null) {
            token = extractBearerToken(request);
        }

        Long userId = authTokenService.validate(token);
        if (userId == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }

        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }

        Map<String, Object> result = new LinkedHashMap<>();
        result.put("id", user.getId());
        result.put("empId", user.getEmpId());
        result.put("userId", user.getEmpId());
        result.put("name", user.getName());
        result.put("userName", user.getName());
        result.put("orgName", user.getOrgName());
        result.put("roleName", user.getRoleName());
        return ResponseEntity.ok(result);
    }

    private Map<String, String> mergeParams(String body, HttpServletRequest request) {
        Map<String, String> params = new LinkedHashMap<>();
        request.getParameterMap().forEach((key, values) -> {
            if (values != null && values.length > 0) {
                params.put(key, values[0]);
            }
        });
        if (body == null || body.isBlank()) {
            return params;
        }

        String trimmedBody = body.trim();
        try {
            if (trimmedBody.startsWith("{")) {
                params.putAll(objectMapper.readValue(trimmedBody, new TypeReference<Map<String, String>>() {
                }));
            } else {
                for (String pair : trimmedBody.split("&")) {
                    int index = pair.indexOf('=');
                    if (index > 0) {
                        params.put(URLDecoder.decode(pair.substring(0, index), StandardCharsets.UTF_8),
                                URLDecoder.decode(pair.substring(index + 1), StandardCharsets.UTF_8));
                    }
                }
            }
        } catch (Exception ignored) {
            // Keep query/form parameters even if an optional compatibility body cannot be parsed.
        }
        return params;
    }

    private String firstNonBlank(String... values) {
        for (String value : values) {
            if (value != null && !value.isBlank()) {
                return value;
            }
        }
        return null;
    }

    private String extractBearerToken(HttpServletRequest request) {
        String authorization = request.getHeader("Authorization");
        if (authorization != null && authorization.startsWith("Bearer ")) {
            return authorization.substring(7);
        }
        return null;
    }
}
