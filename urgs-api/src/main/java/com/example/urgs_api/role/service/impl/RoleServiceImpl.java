package com.example.urgs_api.role.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.role.mapper.RoleMapper;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import org.springframework.stereotype.Service;

import org.springframework.transaction.annotation.Transactional;

import java.util.Set;

@Service
public class RoleServiceImpl extends ServiceImpl<RoleMapper, Role> implements RoleService {

    @Override
    public Set<String> getRolePermissions(Long roleId) {
        return baseMapper.selectRolePermissions(roleId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateRolePermissions(Long roleId, Set<String> permissions) {
        baseMapper.deleteRolePermissions(roleId);
        if (permissions != null && !permissions.isEmpty()) {
            baseMapper.insertRolePermissions(roleId, permissions);
        }
    }
}
