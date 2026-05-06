package com.example.urgs_api.knowledge.controller;

import com.example.urgs_api.knowledge.entity.KnowledgeFolder;
import com.example.urgs_api.knowledge.service.KnowledgeFolderService;
import com.example.urgs_api.knowledge.service.KnowledgeFolderService.FolderTreeNode;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.net.URLEncoder;
import java.util.List;
import java.util.zip.ZipOutputStream;
import java.nio.charset.StandardCharsets;

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
    public ResponseEntity<List<FolderTreeNode>> getFolderTree(
            HttpServletRequest request,
            @RequestParam(defaultValue = "private") String scope) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(folderService.getFolderTree(userId, scope));
    }

    /**
     * 创建文件夹
     */
    @PostMapping
    public ResponseEntity<KnowledgeFolder> createFolder(
            HttpServletRequest request,
            @RequestBody CreateFolderRequest req) {
        Long userId = getUserId(request);
        String scope = req.getScope() != null ? req.getScope() : "private";
        return ResponseEntity.ok(folderService.createFolder(userId, req.getName(), req.getParentId(), scope));
    }

    /**
     * 确保文件夹存在（查找或创建）
     */
    @PostMapping("/ensure")
    public ResponseEntity<KnowledgeFolder> ensureFolder(
            HttpServletRequest request,
            @RequestBody CreateFolderRequest req) {
        Long userId = getUserId(request);
        String scope = req.getScope() != null ? req.getScope() : "private";
        return ResponseEntity.ok(folderService.getOrCreateFolder(userId, req.getName(), req.getParentId(), scope));
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

    @GetMapping("/{id}/download")
    public void downloadFolder(
            @PathVariable Long id,
            HttpServletRequest request,
            HttpServletResponse response) throws IOException {
        Long userId = getUserId(request);

        KnowledgeFolder folder = folderService.getById(id);
        if (folder == null || (!folder.getUserId().equals(userId) && !"shared".equals(folder.getScope()))) {
            response.setStatus(404);
            return;
        }

        String fileName = URLEncoder.encode(folder.getName() + ".zip", StandardCharsets.UTF_8.toString()).replace("+",
                "%20");
        response.setContentType("application/zip");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

        try (ZipOutputStream zos = new ZipOutputStream(response.getOutputStream())) {
            folderService.writeFolderToZip(id, userId, zos, "");
            zos.finish();
        }
    }

    @PostMapping("/download-selected")
    public void downloadSelectedItems(
            @RequestBody BatchDownloadRequest req,
            HttpServletRequest request,
            HttpServletResponse response) throws IOException {
        Long userId = getUserId(request);
        boolean hasDocuments = req.getDocumentIds() != null && !req.getDocumentIds().isEmpty();
        boolean hasFolders = req.getFolderIds() != null && !req.getFolderIds().isEmpty();
        if (!hasDocuments && !hasFolders) {
            response.setStatus(400);
            return;
        }

        String fileName = URLEncoder.encode("知识库打包下载.zip", StandardCharsets.UTF_8.toString()).replace("+", "%20");
        response.setContentType("application/zip");
        response.setHeader("Content-Disposition", "attachment; filename=\"" + fileName + "\"");

        try (ZipOutputStream zos = new ZipOutputStream(response.getOutputStream())) {
            folderService.writeSelectedItemsToZip(req.getDocumentIds(), req.getFolderIds(), userId, zos);
            zos.finish();
        }
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
        private String scope;
    }

    @Data
    public static class UpdateFolderRequest {
        private String name;
        private Long parentId;
        private Integer sortOrder;
    }

    @Data
    public static class BatchDownloadRequest {
        private List<Long> documentIds;
        private List<Long> folderIds;
    }
}
