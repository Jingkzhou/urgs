package com.example.urgs_api.knowledge.controller;

import com.example.urgs_api.knowledge.entity.KnowledgeFolder;
import com.example.urgs_api.knowledge.service.KnowledgeFolderService;
import com.example.urgs_api.knowledge.service.KnowledgeFolderService.FolderTreeNode;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import java.util.List;

/**
 * 知识文件夹控制器
 */
@RestController
@RequestMapping("/api/wiki/folders")
@RequiredArgsConstructor
public class KnowledgeFolderController {

    private final KnowledgeFolderService folderService;

    /**
     * 获取当前用户的文件夹树
     */
    @GetMapping
    public ResponseEntity<List<FolderTreeNode>> getFolderTree(HttpServletRequest request) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(folderService.getFolderTree(userId));
    }

    /**
     * 创建文件夹
     */
    @PostMapping
    public ResponseEntity<KnowledgeFolder> createFolder(
            HttpServletRequest request,
            @RequestBody CreateFolderRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(folderService.createFolder(userId, req.getName(), req.getParentId()));
    }

    /**
     * 更新文件夹
     */
    @PutMapping("/{id}")
    public ResponseEntity<KnowledgeFolder> updateFolder(
            @PathVariable Long id,
            @RequestBody UpdateFolderRequest req) {
        return ResponseEntity.ok(folderService.updateFolder(id, req.getName(), req.getParentId(), req.getSortOrder()));
    }

    /**
     * 删除文件夹
     */
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteFolder(@PathVariable Long id) {
        folderService.deleteFolder(id);
        return ResponseEntity.ok().build();
    }

    /**
     * 获取当前用户ID（从请求属性中获取，由认证过滤器设置）
     */
    private Long getUserId(HttpServletRequest request) {
        Object userId = request.getAttribute("userId");
        if (userId == null) {
            throw new RuntimeException("用户未登录");
        }
        return Long.valueOf(userId.toString());
    }

    @Data
    public static class CreateFolderRequest {
        private String name;
        private Long parentId;
    }

    @Data
    public static class UpdateFolderRequest {
        private String name;
        private Long parentId;
        private Integer sortOrder;
    }
}
