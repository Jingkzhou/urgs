package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.metadata.model.ModelDirectory;

import java.util.List;
import java.util.Map;

/**
 * 模型目录服务接口
 */
public interface ModelDirectoryService extends IService<ModelDirectory> {
    /**
     * 获取模型目录树
     * 
     * @return 目录树结构列表
     */
    List<Map<String, Object>> getTree();
}
