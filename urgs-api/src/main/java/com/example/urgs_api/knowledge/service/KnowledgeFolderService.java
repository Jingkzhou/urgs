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
import java.io.*;
import java.util.zip.*;
import org.springframework.beans.factory.annotation.Value;
import com.example.urgs_api.knowledge.entity.KnowledgeDocument;
import com.example.urgs_api.knowledge.mapper.KnowledgeDocumentMapper;

/**
 * 知识文件夹服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeFolderService {

    private final KnowledgeFolderMapper folderMapper;
    private final KnowledgeDocumentMapper documentMapper;

    @Value("${urgs.profile:./uploads}")
    private String profile;

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
     * 将目录及其子目录下的文件递归写入 ZIP 流
     */
    public void writeFolderToZip(Long folderId, Long userId, ZipOutputStream zos, String currentPath)
            throws IOException {
        // 1. 获取当前目录下所有文档
        LambdaQueryWrapper<KnowledgeDocument> docQuery = new LambdaQueryWrapper<>();
        if (folderId == null) {
            docQuery.isNull(KnowledgeDocument::getFolderId);
        } else {
            docQuery.eq(KnowledgeDocument::getFolderId, folderId);
        }
        docQuery.eq(KnowledgeDocument::getUserId, userId);
        List<KnowledgeDocument> documents = documentMapper.selectList(docQuery);

        for (KnowledgeDocument doc : documents) {
            if (doc.getFileUrl() != null) {
                // 读取原始文件
                String relativePath = doc.getFileUrl().replace("/profile/", "");
                File file = new File(profile, relativePath);
                if (file.exists()) {
                    try (FileInputStream fis = new FileInputStream(file)) {
                        ZipEntry zipEntry = new ZipEntry(currentPath + doc.getFileName());
                        zos.putNextEntry(zipEntry);
                        byte[] bytes = new byte[1024];
                        int length;
                        while ((length = fis.read(bytes)) >= 0) {
                            zos.write(bytes, 0, length);
                        }
                        zos.closeEntry();
                    }
                }
            }
        }

        // 2. 递归子目录
        List<KnowledgeFolder> subFolders;
        if (folderId == null) {
            LambdaQueryWrapper<KnowledgeFolder> folderQuery = new LambdaQueryWrapper<>();
            folderQuery.isNull(KnowledgeFolder::getParentId).eq(KnowledgeFolder::getUserId, userId);
            subFolders = folderMapper.selectList(folderQuery);
        } else {
            subFolders = folderMapper.findByParentId(folderId);
        }

        for (KnowledgeFolder subFolder : subFolders) {
            writeFolderToZip(subFolder.getId(), userId, zos, currentPath + subFolder.getName() + "/");
        }
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
