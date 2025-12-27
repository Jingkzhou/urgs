package com.example.urgs_api.knowledge.controller;

import com.example.urgs_api.knowledge.entity.KnowledgeTag;
import com.example.urgs_api.knowledge.service.KnowledgeTagService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

/**
 * 知识标签控制器
 */
@RestController
@RequestMapping("/api/wiki/tags")
@RequiredArgsConstructor
public class KnowledgeTagController {

    private final KnowledgeTagService tagService;

    /**
     * 获取当前用户的所有标签
     */
    @GetMapping
    public ResponseEntity<List<KnowledgeTag>> listTags(HttpServletRequest request) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(tagService.listTags(userId));
    }

    /**
     * 创建标签
     */
    @PostMapping
    public ResponseEntity<KnowledgeTag> createTag(
            HttpServletRequest request,
            @RequestBody CreateTagRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(tagService.createTag(userId, req.getName(), req.getColor()));
    }

    /**
     * 更新标签
     */
    @PutMapping("/{id}")
    public ResponseEntity<KnowledgeTag> updateTag(
            @PathVariable Long id,
            @RequestBody UpdateTagRequest req) {
        return ResponseEntity.ok(tagService.updateTag(id, req.getName(), req.getColor()));
    }

    /**
     * 删除标签
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTag(@PathVariable Long id) {
        tagService.deleteTag(id);
        return ResponseEntity.ok().build();
    }

    /**
     * 获取文档的标签
     */
    @GetMapping("/document/{documentId}")
    public ResponseEntity<List<KnowledgeTag>> getDocumentTags(@PathVariable Long documentId) {
        return ResponseEntity.ok(tagService.getDocumentTags(documentId));
    }

    private Long getUserId(HttpServletRequest request) {
        Object userId = request.getAttribute("userId");
        if (userId == null) {
            throw new RuntimeException("用户未登录");
        }
        return Long.valueOf(userId.toString());
    }

    @Data
    public static class CreateTagRequest {
        private String name;
        private String color;
    }

    @Data
    public static class UpdateTagRequest {
        private String name;
        private String color;
    }
}
