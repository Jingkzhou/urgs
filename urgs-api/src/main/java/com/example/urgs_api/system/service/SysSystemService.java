package com.example.urgs_api.system.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.system.model.SysSystem;

public interface SysSystemService extends IService<SysSystem> {
    java.util.List<SysSystem> list(Long userId);
}
