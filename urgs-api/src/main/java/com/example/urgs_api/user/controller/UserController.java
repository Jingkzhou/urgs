package com.example.urgs_api.user.controller;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.auth.annotation.RequirePermission;
import com.example.urgs_api.user.dto.UserBatchImportResultDTO;
import com.example.urgs_api.user.dto.UserDTO;
import com.example.urgs_api.user.dto.UserGitIdentityDTO;
import com.example.urgs_api.user.dto.UserRequest;
import com.example.urgs_api.user.mapper.UserGitIdentityMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.model.UserGitIdentity;
import com.example.urgs_api.user.service.UserService;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private static final String DEFAULT_GIT_PLATFORM = "GITLAB";

    private final UserService userService;
    private final UserGitIdentityMapper userGitIdentityMapper;

    public UserController(UserService userService, UserGitIdentityMapper userGitIdentityMapper) {
        this.userService = userService;
        this.userGitIdentityMapper = userGitIdentityMapper;
    }

    @GetMapping
    @RequirePermission("sys:user:query")
    public List<UserDTO> list(@RequestParam(required = false) String keyword) {
        return toDtosWithGitIdentity(userService.searchUsers(keyword));
    }

    @PostMapping
    @RequirePermission("sys:user:add")
    public UserDTO create(@RequestBody UserRequest req) {
        User user = toEntity(req, null);
        validateUniqueEmpId(user.getEmpId(), null);
        // Default password if not provided, though frontend sends "123456"
        if (user.getPassword() == null || user.getPassword().isEmpty()) {
            user.setPassword("123456");
        }
        userService.save(user);
        saveGitIdentity(user.getId(), req);
        return toDtoWithGitIdentity(user);
    }

    @PostMapping("/{id}/reset-password")
    @RequirePermission("sys:user:edit")
    public ResponseEntity<Void> resetPassword(@PathVariable("id") Long id) {
        if (userService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        boolean success = userService.resetPassword(id);
        return success ? ResponseEntity.ok().build() : ResponseEntity.internalServerError().build();
    }

    @PutMapping("/{id}")
    @RequirePermission("sys:user:edit")
    public ResponseEntity<UserDTO> update(@PathVariable("id") Long id, @RequestBody UserRequest req) {
        if (userService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        User user = toEntity(req, id);
        validateUniqueEmpId(user.getEmpId(), id);
        userService.updateById(user);
        saveGitIdentity(id, req);
        return ResponseEntity.ok(toDtoWithGitIdentity(userService.getById(id)));
    }

    @DeleteMapping("/{id}")
    @RequirePermission("sys:user:del")
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        boolean removed = userService.removeById(id);
        return removed ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }

    @PostMapping("/batch")
    @RequirePermission("sys:user:add")
    public ResponseEntity<UserBatchImportResultDTO> batch(@RequestBody List<UserRequest> requests) {
        List<User> users = requests.stream()
                .map(req -> toEntity(req, null))
                .collect(Collectors.toList());
        UserBatchImportResultDTO result = userService.batchUpsert(users);
        return ResponseEntity.ok(result);
    }

    @GetMapping("/export")
    @RequirePermission("sys:user:query")
    public List<UserDTO> export() {
        return toDtosWithGitIdentity(userService.listAll());
    }

    @GetMapping("/{id}/git-identity")
    public ResponseEntity<UserGitIdentityDTO> getGitIdentity(
            @PathVariable("id") String id,
            @RequestParam(required = false, defaultValue = DEFAULT_GIT_PLATFORM) String platform) {
        User user = findUserByIdOrEmpId(id);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }

        UserGitIdentity identity = findGitIdentity(user.getId(), platform);
        if (identity == null || !Boolean.TRUE.equals(identity.getEnabled())) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.ok(UserGitIdentityDTO.fromEntity(identity));
    }

    @GetMapping("/permissions")
    public ResponseEntity<java.util.Set<String>> getMyPermissions(
            @RequestAttribute(value = "userId", required = false) Long userId) {
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        return ResponseEntity.ok(userService.getUserPermissions(userId));
    }

    @PostMapping("/change-password")
    public ResponseEntity<String> changePassword(
            @RequestAttribute(value = "userId", required = false) Long userId,
            @RequestBody com.example.urgs_api.user.dto.ChangePasswordRequest req) {
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        try {
            boolean success = userService.changePassword(userId, req.getOldPassword(), req.getNewPassword());
            return success ? ResponseEntity.ok().build()
                    : ResponseEntity.badRequest().body("Failed to change password");
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(e.getMessage());
        }
    }

    @PostMapping("/profile")
    public ResponseEntity<UserDTO> updateProfile(
            @RequestAttribute(value = "userId", required = false) Long userId,
            @RequestBody UserDTO req) {
        if (userId == null) {
            return ResponseEntity.status(401).build();
        }
        User user = userService.getById(userId);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }

        // Only update allowed fields (e.g., avatar, git token)
        if (req.getAvatarUrl() != null) {
            user.setAvatarUrl(req.getAvatarUrl());
        }

        user.setPassword(null);
        userService.updateById(user);
        return ResponseEntity.ok(UserDTO.fromEntity(user));
    }

    private void validateUniqueEmpId(String empId, Long currentUserId) {
        if (empId == null || empId.isBlank()) {
            return;
        }
        long duplicateCount = userService.lambdaQuery()
                .eq(User::getEmpId, empId.trim())
                .ne(currentUserId != null, User::getId, currentUserId)
                .count();
        if (duplicateCount > 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "工号已存在，不允许保存");
        }
    }

    private List<UserDTO> toDtosWithGitIdentity(List<User> users) {
        if (users == null || users.isEmpty()) {
            return List.of();
        }

        List<Long> userIds = users.stream()
                .map(User::getId)
                .filter(id -> id != null)
                .collect(Collectors.toList());
        Map<Long, UserGitIdentity> identityMap = userIds.isEmpty() ? Map.of()
                : userGitIdentityMapper.selectList(new LambdaQueryWrapper<UserGitIdentity>()
                        .in(UserGitIdentity::getUserId, userIds)
                        .eq(UserGitIdentity::getPlatform, DEFAULT_GIT_PLATFORM)
                        .eq(UserGitIdentity::getEnabled, true))
                        .stream()
                        .collect(Collectors.toMap(UserGitIdentity::getUserId, identity -> identity, (left, right) -> left));

        return users.stream()
                .map(user -> attachGitIdentity(UserDTO.fromEntity(user), identityMap.get(user.getId())))
                .collect(Collectors.toList());
    }

    private UserDTO toDtoWithGitIdentity(User user) {
        if (user == null) {
            return null;
        }
        return attachGitIdentity(UserDTO.fromEntity(user), findGitIdentity(user.getId(), DEFAULT_GIT_PLATFORM));
    }

    private UserDTO attachGitIdentity(UserDTO dto, UserGitIdentity identity) {
        if (dto == null || identity == null || !Boolean.TRUE.equals(identity.getEnabled())) {
            return dto;
        }
        dto.setGitUsername(identity.getGitUsername());
        dto.setGitEmail(identity.getGitEmail());
        dto.setGitUserId(identity.getGitUserId());
        return dto;
    }

    private UserGitIdentity findGitIdentity(Long userId, String platform) {
        if (userId == null) {
            return null;
        }
        return userGitIdentityMapper.selectOne(new LambdaQueryWrapper<UserGitIdentity>()
                .eq(UserGitIdentity::getUserId, userId)
                .eq(UserGitIdentity::getPlatform, normalizeGitPlatform(platform))
                .last("LIMIT 1"));
    }

    private User findUserByIdOrEmpId(String value) {
        String normalized = trimToNull(value);
        if (normalized == null) {
            return null;
        }
        Long userId = parseLong(normalized);
        if (userId != null) {
            User user = userService.getById(userId);
            if (user != null) {
                return user;
            }
        }
        return userService.lambdaQuery()
                .eq(User::getEmpId, normalized)
                .last("LIMIT 1")
                .one();
    }

    private Long parseLong(String value) {
        if (!StringUtils.hasText(value)) {
            return null;
        }
        try {
            return Long.valueOf(value.trim());
        } catch (NumberFormatException ex) {
            return null;
        }
    }

    private void saveGitIdentity(Long userId, UserRequest req) {
        if (userId == null || req == null) {
            return;
        }
        String gitUsername = trimToNull(req.getGitUsername());
        String gitEmail = trimToNull(req.getGitEmail());
        String gitUserId = trimToNull(req.getGitUserId());
        UserGitIdentity existing = findGitIdentity(userId, DEFAULT_GIT_PLATFORM);

        if (!StringUtils.hasText(gitUsername) && !StringUtils.hasText(gitEmail) && !StringUtils.hasText(gitUserId)) {
            if (existing != null) {
                userGitIdentityMapper.deleteById(existing.getId());
            }
            return;
        }

        UserGitIdentity identity = existing == null ? new UserGitIdentity() : existing;
        identity.setUserId(userId);
        identity.setPlatform(DEFAULT_GIT_PLATFORM);
        identity.setGitUsername(gitUsername);
        identity.setGitEmail(gitEmail);
        identity.setGitUserId(gitUserId);
        identity.setEnabled(true);

        if (identity.getId() == null) {
            userGitIdentityMapper.insert(identity);
        } else {
            userGitIdentityMapper.updateById(identity);
        }
    }

    private String normalizeGitPlatform(String platform) {
        String normalized = trimToNull(platform);
        return normalized == null ? DEFAULT_GIT_PLATFORM : normalized.toUpperCase();
    }

    private String trimToNull(String value) {
        return StringUtils.hasText(value) ? value.trim() : null;
    }

    private User toEntity(UserRequest req, Long id) {
        User u = new User();
        u.setId(id);
        u.setEmpId(req.getEmpId() == null ? null : req.getEmpId().trim());
        u.setName(req.getName());
        u.setOrgName(req.getOrgName());
        u.setRoleName(req.getRoleName());
        u.setRoleId(req.getRoleId()); // New: Map roleId
        u.setSystem(req.getSystem());
        u.setPhone(req.getPhone());
        u.setLastLogin(req.getLastLogin());
        u.setStatus(req.getStatus());
        u.setPassword(req.getPassword());
        return u;
    }
}
