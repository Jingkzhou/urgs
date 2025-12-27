package com.example.urgs_api.knowledge.service;

import com.example.urgs_api.knowledge.entity.KnowledgeTag;
import com.example.urgs_api.knowledge.mapper.KnowledgeDocumentMapper;
import com.example.urgs_api.knowledge.mapper.KnowledgeTagMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

/**
 * 知识标签服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeTagService {

    private final KnowledgeTagMapper tagMapper;
    private final KnowledgeDocumentMapper documentMapper;

    /**
     * 获取用户的所有标签
     */
    public List<KnowledgeTag> listTags(Long userId) {
        return tagMapper.findByUserId(userId);
    }

    /**
     * 创建标签
     */
    @Transactional
    public KnowledgeTag createTag(Long userId, String name, String color) {
        // 检查是否已存在
        KnowledgeTag existing = tagMapper.findByUserIdAndName(userId, name);
        if (existing != null) {
            throw new RuntimeException("标签名称已存在");
        }

        KnowledgeTag tag = new KnowledgeTag();
        tag.setUserId(userId);
        tag.setName(name);
        tag.setColor(color != null ? color : "#1890ff");
        tag.setCreateTime(LocalDateTime.now());
        tagMapper.insert(tag);

        log.info("用户 {} 创建标签: {}", userId, name);
        return tag;
    }

    /**
     * 更新标签
     */
    @Transactional
    public KnowledgeTag updateTag(Long id, String name, String color) {
        KnowledgeTag tag = tagMapper.selectById(id);
        if (tag == null) {
            throw new RuntimeException("标签不存在");
        }

        // 检查名称是否重复
        if (name != null && !name.equals(tag.getName())) {
            KnowledgeTag existing = tagMapper.findByUserIdAndName(tag.getUserId(), name);
            if (existing != null) {
                throw new RuntimeException("标签名称已存在");
            }
            tag.setName(name);
        }
        if (color != null) {
            tag.setColor(color);
        }

        tagMapper.updateById(tag);
        return tag;
    }

    /**
     * 删除标签
     */
    @Transactional
    public void deleteTag(Long id) {
        // 先删除关联关系
        documentMapper.deleteTagDocuments(id);
        tagMapper.deleteById(id);
        log.info("删除标签: {}", id);
    }

    /**
     * 获取文档的标签
     */
    public List<KnowledgeTag> getDocumentTags(Long documentId) {
        return tagMapper.findByDocumentId(documentId);
    }
}
