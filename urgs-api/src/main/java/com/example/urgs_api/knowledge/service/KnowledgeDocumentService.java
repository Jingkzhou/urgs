package com.example.urgs_api.knowledge.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.core.metadata.IPage;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.knowledge.entity.KnowledgeDocument;
import com.example.urgs_api.knowledge.mapper.KnowledgeDocumentMapper;
import com.example.urgs_api.knowledge.mapper.KnowledgeTagMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.StringUtils;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 知识文档服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeDocumentService {

    private final KnowledgeDocumentMapper documentMapper;
    private final KnowledgeTagMapper tagMapper;

    /**
     * 分页查询文档
     */
    public IPage<KnowledgeDocument> listDocuments(Long userId, Long folderId, String keyword,
            Boolean favorite,
            int page, int size) {
        return listDocuments(userId, folderId, keyword, favorite, page, size, "private");
    }

    /**
     * 分页查询文档（指定空间）
     * scope=shared 时不过滤 userId，scope=private 时按 userId 过滤
     */
    public IPage<KnowledgeDocument> listDocuments(Long userId, Long folderId, String keyword,
            Boolean favorite,
            int page, int size, String scope) {
        LambdaQueryWrapper<KnowledgeDocument> wrapper = new LambdaQueryWrapper<>();

        if ("shared".equals(scope)) {
            wrapper.eq(KnowledgeDocument::getScope, "shared");
        } else {
            wrapper.eq(KnowledgeDocument::getUserId, userId);
            wrapper.eq(KnowledgeDocument::getScope, "private");
        }

        if (folderId != null) {
            wrapper.eq(KnowledgeDocument::getFolderId, folderId);
        } else if (!StringUtils.hasText(keyword)) {
            wrapper.isNull(KnowledgeDocument::getFolderId);
        }
        if (StringUtils.hasText(keyword)) {
            wrapper.like(KnowledgeDocument::getTitle, keyword);
        }
        if (Boolean.TRUE.equals(favorite)) {
            wrapper.eq(KnowledgeDocument::getIsFavorite, 1);
        }

        wrapper.orderByDesc(KnowledgeDocument::getUpdateTime);

        return documentMapper.selectPage(new Page<>(page, size), wrapper);
    }

    /**
     * 创建文档
     */
    @Transactional
    public KnowledgeDocument createDocument(Long userId, KnowledgeDocument doc, List<Long> tagIds) {
        doc.setUserId(userId);
        doc.setIsFavorite(0);
        doc.setViewCount(0);
        doc.setCreateTime(LocalDateTime.now());
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.insert(doc);

        // 关联标签
        if (tagIds != null && !tagIds.isEmpty()) {
            for (Long tagId : tagIds) {
                documentMapper.addDocumentTag(doc.getId(), tagId);
            }
        }

        log.info("用户 {} 上传附件: {}", userId, doc.getTitle());
        return doc;
    }

    /**
     * 更新文档信息
     */
    @Transactional
    public KnowledgeDocument updateDocument(Long id, KnowledgeDocument updates, List<Long> tagIds) {
        KnowledgeDocument doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new RuntimeException("文档不存在");
        }

        if (updates.getTitle() != null)
            doc.setTitle(updates.getTitle());
        if (updates.getFileName() != null)
            doc.setFileName(updates.getFileName());
        if (updates.getFolderId() != null)
            doc.setFolderId(updates.getFolderId());

        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);

        // 更新标签关联
        if (tagIds != null) {
            documentMapper.deleteDocumentTags(id);
            for (Long tagId : tagIds) {
                documentMapper.addDocumentTag(id, tagId);
            }
        }

        return doc;
    }

    /**
     * 删除文档
     */
    @Transactional
    public void deleteDocument(Long id) {
        documentMapper.deleteDocumentTags(id);
        documentMapper.deleteById(id);
        log.info("删除文档: {}", id);
    }

    /**
     * 切换收藏状态
     */
    @Transactional
    public boolean toggleFavorite(Long id) {
        KnowledgeDocument doc = documentMapper.selectById(id);
        if (doc == null) {
            throw new RuntimeException("文档不存在");
        }
        int newStatus = doc.getIsFavorite() == 1 ? 0 : 1;
        doc.setIsFavorite(newStatus);
        doc.setUpdateTime(LocalDateTime.now());
        documentMapper.updateById(doc);
        return newStatus == 1;
    }

    /**
     * 复制共享文档到个人空间
     */
    @Transactional
    public KnowledgeDocument copyToPrivate(Long docId, Long userId) {
        KnowledgeDocument source = documentMapper.selectById(docId);
        if (source == null) {
            throw new RuntimeException("文档不存在");
        }
        if (!"shared".equals(source.getScope())) {
            throw new RuntimeException("只能从共享空间复制文档");
        }

        KnowledgeDocument copy = new KnowledgeDocument();
        copy.setUserId(userId);
        copy.setFolderId(null); // 复制到个人空间根目录
        copy.setTitle(source.getTitle());
        copy.setScope("private");
        copy.setSourceDocId(source.getId());
        copy.setFileUrl(source.getFileUrl());
        copy.setFileName(source.getFileName());
        copy.setFileSize(source.getFileSize());
        copy.setIsFavorite(0);
        copy.setViewCount(0);
        copy.setCreateTime(LocalDateTime.now());
        copy.setUpdateTime(LocalDateTime.now());
        documentMapper.insert(copy);

        log.info("用户 {} 从共享空间复制文档 {} 到个人空间", userId, docId);
        return copy;
    }

    /**
     * 批量删除文档
     */
    @Transactional
    public int batchDeleteDocuments(List<Long> ids) {
        if (ids == null || ids.isEmpty()) return 0;
        for (Long id : ids) {
            documentMapper.deleteDocumentTags(id);
        }
        int count = documentMapper.deleteBatchIds(ids);
        log.info("批量删除文档: {} 个", count);
        return count;
    }

    /**
     * 批量移动文档到目标文件夹
     */
    @Transactional
    public int batchMoveDocuments(List<Long> ids, Long folderId) {
        if (ids == null || ids.isEmpty()) return 0;
        int count = 0;
        for (Long id : ids) {
            KnowledgeDocument doc = documentMapper.selectById(id);
            if (doc != null) {
                doc.setFolderId(folderId);
                doc.setUpdateTime(LocalDateTime.now());
                documentMapper.updateById(doc);
                count++;
            }
        }
        log.info("批量移动文档到文件夹 {}: {} 个", folderId, count);
        return count;
    }

    /**
     * 批量给文档打标签
     */
    @Transactional
    public int batchTagDocuments(List<Long> ids, List<Long> tagIds) {
        if (ids == null || ids.isEmpty() || tagIds == null || tagIds.isEmpty()) return 0;
        int count = 0;
        for (Long docId : ids) {
            KnowledgeDocument doc = documentMapper.selectById(docId);
            if (doc != null) {
                for (Long tagId : tagIds) {
                    // 避免重复关联：先查再加
                    List<Long> existingTags = documentMapper.findTagIdsByDocumentId(docId);
                    if (!existingTags.contains(tagId)) {
                        documentMapper.addDocumentTag(docId, tagId);
                    }
                }
                count++;
            }
        }
        log.info("批量打标签: {} 个文档, {} 个标签", count, tagIds.size());
        return count;
    }

    /**
     * 获取最近访问的文档
     */
    public List<KnowledgeDocument> getRecentDocuments(Long userId, int limit) {
        LambdaQueryWrapper<KnowledgeDocument> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(KnowledgeDocument::getUserId, userId)
                .eq(KnowledgeDocument::getScope, "private")
                .orderByDesc(KnowledgeDocument::getUpdateTime)
                .last("LIMIT " + limit);
        return documentMapper.selectList(wrapper);
    }

    /**
     * 获取收藏的文档
     */
    public List<KnowledgeDocument> getFavoriteDocuments(Long userId) {
        LambdaQueryWrapper<KnowledgeDocument> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(KnowledgeDocument::getUserId, userId)
                .eq(KnowledgeDocument::getScope, "private")
                .eq(KnowledgeDocument::getIsFavorite, 1)
                .orderByDesc(KnowledgeDocument::getUpdateTime);
        return documentMapper.selectList(wrapper);
    }
}
