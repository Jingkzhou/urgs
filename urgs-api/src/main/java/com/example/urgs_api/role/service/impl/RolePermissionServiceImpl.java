package com.example.urgs_api.role.service.impl;

import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.role.mapper.RolePermissionMapper;
import com.example.urgs_api.role.model.RolePermission;
import com.example.urgs_api.role.service.RolePermissionService;
import org.springframework.stereotype.Service;

@Service
public class RolePermissionServiceImpl extends ServiceImpl<RolePermissionMapper, RolePermission> implements RolePermissionService {
}
