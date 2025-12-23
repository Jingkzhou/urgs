package com.example.urgs_api.user.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.user.mapper.UserMapper;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
public class UserServiceImpl extends ServiceImpl<UserMapper, User> implements UserService {

    private final PasswordEncoder passwordEncoder;

    public UserServiceImpl(PasswordEncoder passwordEncoder) {
        this.passwordEncoder = passwordEncoder;
    }

    @Override
    public boolean save(User entity) {
        if (entity.getPassword() != null) {
            entity.setPassword(passwordEncoder.encode(entity.getPassword()));
        }
        return super.save(entity);
    }

    @Override
    public boolean updateById(User entity) {
        if (entity.getPassword() != null && !entity.getPassword().isEmpty()) {
            entity.setPassword(passwordEncoder.encode(entity.getPassword()));
        }
        return super.updateById(entity);
    }

    @Override
    public boolean resetPassword(Long id) {
        User user = new User();
        user.setId(id);
        user.setPassword(passwordEncoder.encode("123456"));
        return super.updateById(user);
    }

    @Override
    public java.util.Set<String> getUserPermissions(Long userId) {
        return baseMapper.selectUserPermissions(userId);
    }

    @Override
    public boolean changePassword(Long userId, String oldPassword, String newPassword) {
        User user = getById(userId);
        if (user == null) {
            return false;
        }
        if (!passwordEncoder.matches(oldPassword, user.getPassword())) {
            throw new IllegalArgumentException("Incorrect old password");
        }
        user.setPassword(passwordEncoder.encode(newPassword));
        // Use updateById from IService to save the new password, bypassing the override
        // which re-encodes if already encoded?
        // Actually the override checks if password is not null. But here we already
        // encoded it.
        // Wait, updateById override encodes if password is NOT null. if we encode it
        // here, then call super.updateById ??
        // The override updateById:
        // if (entity.getPassword() != null ... )
        // entity.setPassword(encoder.encode(entity.getPassword()))
        // So if we set encoded password here, it will be encoded AGAIN in updateById.
        // We should use baseMapper.updateById directly to avoid double encoding, OR let
        // updateById handle encoding.

        // Better approach: Let updateById handle encoding. We just pass plain text to
        // updateById?
        // No, changePassword logic usually verifies old password then sets new one.
        // If we use this.updateById(user) and user has new plain text password, it
        // works.

        user.setPassword(newPassword); // Set plain text, let updateById encode it.
        return this.updateById(user);
    }

    @Override
    public java.util.List<User> searchUsers(String keyword) {
        if (keyword == null || keyword.trim().isEmpty()) {
            return list();
        }
        return list(new com.baomidou.mybatisplus.core.conditions.query.QueryWrapper<User>()
                .like("name", keyword)
                .or()
                .like("emp_id", keyword)
                .or()
                .like("role_name", keyword)); // Also search by role? Maybe useful.
    }
}
