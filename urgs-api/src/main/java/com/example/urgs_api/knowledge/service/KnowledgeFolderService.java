package com.example.urgs_api.knowledge.service;

import com.example.urgs_api.knowledge.entity.KnowledgeFolder;
import com.example.urgs_api.knowledge.mapper.KnowledgeFolderMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

/**
 * 知识文件夹服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeFolderService {

    private final KnowledgeFolderMapper folderMapper;

    /**
     * 获取用户的文件夹树结构
     */
    public List<FolderTreeNode> getFolderTree(Long userId) {
        List<KnowledgeFolder> folders = folderMapper.findByUserId(userId);
        return buildTree(folders, null);
    }

    /**
     * 构建树形结构
     */
    private List<FolderTreeNode> buildTree(List<KnowledgeFolder> folders, Long parentId) {
        Map<Long, List<KnowledgeFolder>> grouped = folders.stream()
                .collect(Collectors.groupingBy(f -> f.getParentId() == null ? -1L : f.getParentId()));

        List<KnowledgeFolder> roots = grouped.getOrDefault(parentId == null ? -1L : parentId, new ArrayList<>());

        return roots.stream().map(folder -> {
            FolderTreeNode node = new FolderTreeNode();
            node.setId(folder.getId());
            node.setName(folder.getName());
            node.setParentId(folder.getParentId());
            node.setSortOrder(folder.getSortOrder());
            node.setChildren(buildTreeRecursive(folders, folder.getId()));
            return node;
        }).collect(Collectors.toList());
    }

    private List<FolderTreeNode> buildTreeRecursive(List<KnowledgeFolder> allFolders, Long parentId) {
        return allFolders.stream()
                .filter(f -> parentId.equals(f.getParentId()))
                .map(folder -> {
                    FolderTreeNode node = new FolderTreeNode();
                    node.setId(folder.getId());
                    node.setName(folder.getName());
                    node.setParentId(folder.getParentId());
                    node.setSortOrder(folder.getSortOrder());
                    node.setChildren(buildTreeRecursive(allFolders, folder.getId()));
                    return node;
                }).collect(Collectors.toList());
    }

    /**
     * 创建文件夹
     */
    @Transactional
    public KnowledgeFolder createFolder(Long userId, String name, Long parentId) {
        KnowledgeFolder folder = new KnowledgeFolder();
        folder.setUserId(userId);
        folder.setName(name);
        folder.setParentId(parentId);
        folder.setSortOrder(0);
        folder.setCreateTime(LocalDateTime.now());
        folder.setUpdateTime(LocalDateTime.now());
        folderMapper.insert(folder);
        log.info("用户 {} 创建文件夹: {}", userId, name);
        return folder;
    }

    /**
     * 更新文件夹
     */
    @Transactional
    public KnowledgeFolder updateFolder(Long id, String name, Long parentId, Integer sortOrder) {
        KnowledgeFolder folder = folderMapper.selectById(id);
        if (folder == null) {
            throw new RuntimeException("文件夹不存在");
        }
        if (name != null)
            folder.setName(name);
        if (parentId != null)
            folder.setParentId(parentId);
        if (sortOrder != null)
            folder.setSortOrder(sortOrder);
        folder.setUpdateTime(LocalDateTime.now());
        folderMapper.updateById(folder);
        return folder;
    }

    /**
     * 删除文件夹（同时删除子文件夹）
     */
    @Transactional
    public void deleteFolder(Long id) {
        // 递归删除子文件夹
        List<KnowledgeFolder> children = folderMapper.findByParentId(id);
        for (KnowledgeFolder child : children) {
            deleteFolder(child.getId());
        }
        folderMapper.deleteById(id);
        log.info("删除文件夹: {}", id);
    }

    /**
     * 获取文件夹详情
     */
    public KnowledgeFolder getById(Long id) {
        return folderMapper.selectById(id);
    }

    /**
     * 文件夹树节点 VO
     */
    @lombok.Data
    public static class FolderTreeNode {
        private Long id;
        private String name;
        private Long parentId;
        private Integer sortOrder;
        private List<FolderTreeNode> children;
    }
}
