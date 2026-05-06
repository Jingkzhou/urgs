package com.example.urgs_api.knowledge.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.example.urgs_api.knowledge.entity.KnowledgeDocument;
import com.example.urgs_api.knowledge.entity.KnowledgeTag;
import com.example.urgs_api.knowledge.service.KnowledgeDocumentService;
import com.example.urgs_api.knowledge.service.KnowledgeTagService;
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
    private final KnowledgeTagService tagService;

    /**
     * 分页查询文档
     */
    @GetMapping
    public ResponseEntity<IPage<KnowledgeDocument>> listDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) Long folderId,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) Boolean favorite,
            @RequestParam(required = false) Long tagId,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "private") String scope) {
        Long userId = getUserId(request);
        return ResponseEntity
                .ok(documentService.listDocuments(userId, folderId, keyword, favorite, tagId, page, size, scope));
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
        doc.setScope(req.getScope() != null ? req.getScope() : "private");
        doc.setFileUrl(req.getFileUrl());
        doc.setFileName(req.getFileName());
        doc.setFileSize(req.getFileSize());

        return ResponseEntity.ok(documentService.createDocument(userId, doc, req.getTagIds()));
    }

    /**
     * 复制共享文档到个人空间
     */
    @PostMapping("/{id}/copy-to-private")
    public ResponseEntity<KnowledgeDocument> copyToPrivate(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.copyToPrivate(id, userId));
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
        updates.setFileName(req.getFileName());
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

    /**
     * 批量删除文档
     */
    @PostMapping("/batch-delete")
    public ResponseEntity<Map<String, Integer>> batchDeleteDocuments(
            @RequestBody BatchIdsRequest req) {
        int count = documentService.batchDeleteDocuments(req.getIds());
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * 批量移动文档到目标文件夹
     */
    @PostMapping("/batch-move")
    public ResponseEntity<Map<String, Integer>> batchMoveDocuments(
            @RequestBody BatchMoveRequest req) {
        int count = documentService.batchMoveDocuments(req.getIds(), req.getFolderId());
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * 批量给文档打标签
     */
    @PostMapping("/batch-tag")
    public ResponseEntity<Map<String, Integer>> batchTagDocuments(
            @RequestBody BatchTagRequest req) {
        int count = documentService.batchTagDocuments(req.getIds(), req.getTagIds());
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * 批量获取文档的标签映射
     */
    @PostMapping("/tags-map")
    public ResponseEntity<Map<Long, List<KnowledgeTag>>> getDocumentTagsMap(
            @RequestBody BatchIdsRequest req) {
        return ResponseEntity.ok(tagService.getDocumentTagsMap(req.getIds()));
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
        private String scope;
        private String fileUrl;
        private String fileName;
        private Long fileSize;
        private List<Long> tagIds;
    }

    @Data
    public static class UpdateDocumentRequest {
        private Long folderId;
        private String title;
        private String fileName;
        private List<Long> tagIds;
    }

    @Data
    public static class BatchIdsRequest {
        private List<Long> ids;
    }

    @Data
    public static class BatchMoveRequest {
        private List<Long> ids;
        private Long folderId;
    }

    @Data
    public static class BatchTagRequest {
        private List<Long> ids;
        private List<Long> tagIds;
    }
}
