package com.example.urgs_api.knowledge.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.example.urgs_api.knowledge.entity.KnowledgeDocument;
import com.example.urgs_api.knowledge.service.KnowledgeDocumentService;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;
import java.util.Map;

/**
 * 知识文档（附件）控制器
 */
@RestController
@RequestMapping("/api/wiki/documents")
@RequiredArgsConstructor
public class KnowledgeDocumentController {

    private final KnowledgeDocumentService documentService;

    /**
     * 分页查询文档
     */
    @GetMapping
    public ResponseEntity<IPage<KnowledgeDocument>> listDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) Long folderId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean favorite,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = getUserId(request);
        return ResponseEntity
                .ok(documentService.listDocuments(userId, folderId, keyword, favorite, page, size));
    }

    /**
     * 创建文档（附件上传记录）
     */
    @PostMapping
    public ResponseEntity<KnowledgeDocument> createDocument(
            HttpServletRequest request,
            @RequestBody CreateDocumentRequest req) {
        Long userId = getUserId(request);

        KnowledgeDocument doc = new KnowledgeDocument();
        doc.setFolderId(req.getFolderId());
        doc.setTitle(req.getTitle());
        doc.setFileUrl(req.getFileUrl());
        doc.setFileName(req.getFileName());
        doc.setFileSize(req.getFileSize());

        return ResponseEntity.ok(documentService.createDocument(userId, doc, req.getTagIds()));
    }

    /**
     * 更新文档信息
     */
    @PutMapping("/{id}")
    public ResponseEntity<KnowledgeDocument> updateDocument(
            @PathVariable Long id,
            @RequestBody UpdateDocumentRequest req) {
        KnowledgeDocument updates = new KnowledgeDocument();
        updates.setTitle(req.getTitle());
        updates.setFolderId(req.getFolderId());

        return ResponseEntity.ok(documentService.updateDocument(id, updates, req.getTagIds()));
    }

    /**
     * 删除文档
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDocument(@PathVariable Long id) {
        documentService.deleteDocument(id);
        return ResponseEntity.ok().build();
    }

    /**
     * 切换收藏状态
     */
    @PutMapping("/{id}/favorite")
    public ResponseEntity<Map<String, Boolean>> toggleFavorite(@PathVariable Long id) {
        boolean isFavorite = documentService.toggleFavorite(id);
        return ResponseEntity.ok(Map.of("favorite", isFavorite));
    }

    /**
     * 获取最近访问的文档
     */
    @GetMapping("/recent")
    public ResponseEntity<List<KnowledgeDocument>> getRecentDocuments(
            HttpServletRequest request,
            @RequestParam(defaultValue = "10") int limit) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.getRecentDocuments(userId, limit));
    }

    /**
     * 获取收藏的文档
     */
    @GetMapping("/favorites")
    public ResponseEntity<List<KnowledgeDocument>> getFavoriteDocuments(HttpServletRequest request) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.getFavoriteDocuments(userId));
    }

    private Long getUserId(HttpServletRequest request) {
        Object userId = request.getAttribute("userId");
        if (userId == null) {
            throw new RuntimeException("用户未登录");
        }
        return Long.valueOf(userId.toString());
    }

    @Data
    public static class CreateDocumentRequest {
        private Long folderId;
        private String title;
        private String fileUrl;
        private String fileName;
        private Long fileSize;
        private List<Long> tagIds;
    }

    @Data
    public static class UpdateDocumentRequest {
        private Long folderId;
        private String title;
        private List<Long> tagIds;
    }
}
