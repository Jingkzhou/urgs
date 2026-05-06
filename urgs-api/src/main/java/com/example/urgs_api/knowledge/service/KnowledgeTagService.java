package com.example.urgs_api.knowledge.service;

import com.example.urgs_api.knowledge.entity.KnowledgeTag;
import com.example.urgs_api.knowledge.mapper.KnowledgeDocumentMapper;
import com.example.urgs_api.knowledge.mapper.KnowledgeTagMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.*;
import java.util.stream.Collectors;

/**
 * 知识标签服务
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class KnowledgeTagService {

    private static final int TAG_NAME_MAX_LENGTH = 50;

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
        validateTagName(name);
        name = name.trim();
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
            validateTagName(name);
            name = name.trim();
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

    private void validateTagName(String name) {
        if (name == null || name.trim().isEmpty()) {
            throw new RuntimeException("标签名称不能为空");
        }
        if (name.length() > TAG_NAME_MAX_LENGTH) {
            throw new RuntimeException("标签名称不能超过50个字符");
        }
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

    /**
     * 批量获取多个文档的标签映射
     */
    public Map<Long, List<KnowledgeTag>> getDocumentTagsMap(List<Long> documentIds) {
        if (documentIds == null || documentIds.isEmpty()) {
            return Collections.emptyMap();
        }
        List<Map<String, Object>> rows = tagMapper.findTagsByDocumentIds(documentIds);
        Map<Long, List<KnowledgeTag>> result = new HashMap<>();
        for (Map<String, Object> row : rows) {
            Long docId = ((Number) row.get("document_id")).longValue();
            KnowledgeTag tag = new KnowledgeTag();
            tag.setId(((Number) row.get("id")).longValue());
            tag.setUserId(((Number) row.get("user_id")).longValue());
            tag.setName((String) row.get("name"));
            tag.setColor((String) row.get("color"));
            if (row.get("create_time") instanceof LocalDateTime) {
                tag.setCreateTime((LocalDateTime) row.get("create_time"));
            }
            result.computeIfAbsent(docId, k -> new ArrayList<>()).add(tag);
        }
        return result;
    }
}
