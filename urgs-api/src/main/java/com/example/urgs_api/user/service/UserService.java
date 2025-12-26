package com.example.urgs_api.user.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.user.model.User;

public interface UserService extends IService<User> {
    boolean resetPassword(Long id);

    java.util.Set<String> getUserPermissions(Long userId);

    boolean changePassword(Long userId, String oldPassword, String newPassword);

    java.util.List<User> searchUsers(String keyword);

    void batchUpsert(java.util.List<User> users);

    java.util.List<User> listAll();
}
