package com.example.urgs_api.user.controller;

import com.example.urgs_api.user.dto.UserDTO;
import com.example.urgs_api.user.dto.UserRequest;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/users")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping
    public List<UserDTO> list(@RequestParam(required = false) String keyword) {
        return userService.searchUsers(keyword).stream().map(UserDTO::fromEntity).collect(Collectors.toList());
    }

    @PostMapping
    public UserDTO create(@RequestBody UserRequest req) {
        User user = toEntity(req, null);
        // Default password if not provided, though frontend sends "123456"
        if (user.getPassword() == null || user.getPassword().isEmpty()) {
            user.setPassword("123456");
        }
        userService.save(user);
        return UserDTO.fromEntity(user);
    }

    @PostMapping("/{id}/reset-password")
    public ResponseEntity<Void> resetPassword(@PathVariable("id") Long id) {
        if (userService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        boolean success = userService.resetPassword(id);
        return success ? ResponseEntity.ok().build() : ResponseEntity.internalServerError().build();
    }

    @PutMapping("/{id}")
    public ResponseEntity<UserDTO> update(@PathVariable("id") Long id, @RequestBody UserRequest req) {
        if (userService.getById(id) == null) {
            return ResponseEntity.notFound().build();
        }
        User user = toEntity(req, id);
        userService.updateById(user);
        return ResponseEntity.ok(UserDTO.fromEntity(userService.getById(id)));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable("id") Long id) {
        boolean removed = userService.removeById(id);
        return removed ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
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

        // Only update allowed fields (e.g., avatar)
        if (req.getAvatarUrl() != null) {
            user.setAvatarUrl(req.getAvatarUrl());
        }
        // Add other profile fields here if needed later (phone, email etc)

        userService.updateById(user);
        return ResponseEntity.ok(UserDTO.fromEntity(user));
    }

    private User toEntity(UserRequest req, Long id) {
        User u = new User();
        u.setId(id);
        u.setEmpId(req.getEmpId());
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
