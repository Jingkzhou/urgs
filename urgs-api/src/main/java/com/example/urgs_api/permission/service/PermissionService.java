package com.example.urgs_api.permission.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.permission.dto.PermissionDTO;
import com.example.urgs_api.permission.dto.PermissionDiffResponse;
import com.example.urgs_api.permission.model.Permission;

import java.util.List;

public interface PermissionService extends IService<Permission> {
    PermissionDiffResponse diffAgainst(List<PermissionDTO> baseline);

    void sync(List<PermissionDTO> items);

    List<PermissionDTO> listAll();
}
