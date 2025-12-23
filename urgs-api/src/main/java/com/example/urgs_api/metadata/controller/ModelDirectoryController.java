package com.example.urgs_api.metadata.controller;

import com.example.urgs_api.metadata.model.ModelDirectory;
import com.example.urgs_api.metadata.service.ModelDirectoryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/metadata/model-directory")
/**
 * 模型目录控制器
 * 管理模型目录结构
 */
public class ModelDirectoryController {

    @Autowired
    private ModelDirectoryService modelDirectoryService;

    /**
     * 获取目录树结构
     *
     * @return 目录树
     */
    @GetMapping("/tree")
    public List<Map<String, Object>> getTree() {
        return modelDirectoryService.getTree();
    }

    /**
     * 创建目录
     *
     * @param directory 目录对象
     * @return 是否成功
     */
    @PostMapping
    public boolean create(@RequestBody ModelDirectory directory) {
        return modelDirectoryService.save(directory);
    }

    /**
     * 更新目录
     *
     * @param directory 目录对象
     * @return 是否成功
     */
    @PutMapping
    public boolean update(@RequestBody ModelDirectory directory) {
        return modelDirectoryService.updateById(directory);
    }

    /**
     * 删除目录
     *
     * @param id 目录ID
     * @return 是否成功
     */
    @DeleteMapping("/{id}")
    public boolean delete(@PathVariable String id) {
        return modelDirectoryService.removeById(id);
    }
}
