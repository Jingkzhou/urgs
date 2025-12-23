package com.example.urgs_api.metadata.service.impl;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.metadata.mapper.ModelDirectoryMapper;
import com.example.urgs_api.metadata.model.ModelDirectory;
import com.example.urgs_api.metadata.service.ModelDirectoryService;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
/**
 * 模型目录服务实现类
 */
public class ModelDirectoryServiceImpl extends ServiceImpl<ModelDirectoryMapper, ModelDirectory>
        implements ModelDirectoryService {

    @Override
    /**
     * 获取目录树
     */
    public List<Map<String, Object>> getTree() {
        List<ModelDirectory> all = list(
                new LambdaQueryWrapper<ModelDirectory>().orderByAsc(ModelDirectory::getSortOrder));
        return buildTree(all, null);
    }

    /**
     * 递归构建树
     */
    private List<Map<String, Object>> buildTree(List<ModelDirectory> all, String parentId) {
        List<Map<String, Object>> tree = new ArrayList<>();
        for (ModelDirectory dir : all) {
            if ((parentId == null && dir.getParentId() == null)
                    || (parentId != null && parentId.equals(dir.getParentId()))) {
                Map<String, Object> node = new HashMap<>();
                node.put("id", dir.getId());
                node.put("name", dir.getName());
                node.put("parentId", dir.getParentId());
                List<Map<String, Object>> children = buildTree(all, dir.getId());
                if (!children.isEmpty()) {
                    node.put("children", children);
                }
                tree.add(node);
            }
        }
        return tree;
    }
}
