package com.example.urgs_api.role.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.role.model.Role;

import java.util.Set;

public interface RoleService extends IService<Role> {
    Set<String> getRolePermissions(Long roleId);

    void updateRolePermissions(Long roleId, Set<String> permissions);
}
