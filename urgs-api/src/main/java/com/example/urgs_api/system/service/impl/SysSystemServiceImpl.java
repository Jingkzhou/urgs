package com.example.urgs_api.system.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.system.mapper.SysSystemMapper;
import com.example.urgs_api.system.model.SysSystem;
import com.example.urgs_api.system.service.SysSystemService;
import org.springframework.stereotype.Service;

@Service
@lombok.RequiredArgsConstructor
public class SysSystemServiceImpl extends ServiceImpl<SysSystemMapper, SysSystem> implements SysSystemService {

    private final com.example.urgs_api.user.service.UserService userService;

    @Override
    public java.util.List<SysSystem> list(Long userId) {
        if (userId == null) {
            return this.list();
        }
        com.example.urgs_api.user.model.User user = userService.getById(userId);
        if (user == null || user.getSystem() == null || user.getSystem().isBlank()
                || "ALL".equalsIgnoreCase(user.getSystem())) {
            return this.list();
        }

        java.util.List<String> allowedNames = java.util.Arrays.stream(user.getSystem().split(","))
                .map(String::trim)
                .filter(s -> !s.isEmpty())
                .collect(java.util.stream.Collectors.toList());

        return this.list(new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<SysSystem>()
                .in("name", allowedNames));
    }
}
