package com.example.urgs_api.system.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.system.model.SysSystem;

public interface SysSystemService extends IService<SysSystem> {
    java.util.List<SysSystem> getSystems(Long userId, boolean showAll);

    // Keep overload for backward compatibility if needed, or update callers
    default java.util.List<SysSystem> list(Long userId) {
        return getSystems(userId, false);
    }
}
