package com.example.urgs_api.auth.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.auth.dto.AuthResponse;
import com.example.urgs_api.auth.dto.LoginRequest;
import com.example.urgs_api.auth.service.AuthTokenService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final UserService userService;
    private final AuthTokenService authTokenService;
    private final com.example.urgs_api.role.service.RoleService roleService;
    private final org.springframework.security.crypto.password.PasswordEncoder passwordEncoder;

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

        Long roleId = user.getRoleId(); // New: Use stored ID directly
        if (roleId == null && StringUtils.hasText(user.getRoleName())) {
            // Fallback for legacy data without role_id
            com.example.urgs_api.role.model.Role role = roleService.getOne(
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.example.urgs_api.role.model.Role>()
                            .eq(com.example.urgs_api.role.model.Role::getName, user.getRoleName())
                            .or()
                            .eq(com.example.urgs_api.role.model.Role::getCode, user.getRoleName()));
            if (role != null) {
                roleId = role.getId();
            }
        }

        return ResponseEntity
                .ok(new AuthResponse(token, String.valueOf(user.getId()), user.getEmpId(), user.getName(),
                        user.getRoleName(), roleId, user.getSsoSystem()));
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

        Long roleId = user.getRoleId(); // New: Use stored ID directly
        if (roleId == null && StringUtils.hasText(user.getRoleName())) {
            // Fallback for legacy data without role_id
            com.example.urgs_api.role.model.Role role = roleService.getOne(
                    new com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper<com.example.urgs_api.role.model.Role>()
                            .eq(com.example.urgs_api.role.model.Role::getName, user.getRoleName())
                            .or()
                            .eq(com.example.urgs_api.role.model.Role::getCode, user.getRoleName()));
            if (role != null) {
                roleId = role.getId();
            }
        }

        return ResponseEntity
                .ok(new AuthResponse(token, String.valueOf(user.getId()), user.getEmpId(), user.getName(),
                        user.getRoleName(), roleId, user.getSsoSystem()));
    }

    private String extractToken(String authorization, String tokenParam) {
        if (StringUtils.hasText(tokenParam))
            return tokenParam;
        if (StringUtils.hasText(authorization) && authorization.startsWith("Bearer ")) {
            return authorization.substring("Bearer ".length());
        }
        return null;
    }
}
