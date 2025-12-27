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
        LambdaQueryWrapper<KnowledgeDocument> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(KnowledgeDocument::getUserId, userId);

        if (folderId != null) {
            wrapper.eq(KnowledgeDocument::getFolderId, folderId);
        } else if (!StringUtils.hasText(keyword)) {
            // 如果未指定文件夹且没有搜索关键词，则只查询根目录下的文件
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
     * 获取最近访问的文档
     */
    public List<KnowledgeDocument> getRecentDocuments(Long userId, int limit) {
        LambdaQueryWrapper<KnowledgeDocument> wrapper = new LambdaQueryWrapper<>();
        wrapper.eq(KnowledgeDocument::getUserId, userId)
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
                .eq(KnowledgeDocument::getIsFavorite, 1)
                .orderByDesc(KnowledgeDocument::getUpdateTime);
        return documentMapper.selectList(wrapper);
    }
}
