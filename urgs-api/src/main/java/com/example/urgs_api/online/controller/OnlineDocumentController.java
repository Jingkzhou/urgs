package com.example.urgs_api.online.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.common.exception.UnauthorizedException;
import com.example.urgs_api.online.dto.*;
import com.example.urgs_api.online.entity.OnlineDocument;
import com.example.urgs_api.online.service.OnlineDocumentService;
import com.example.urgs_api.user.dto.UserDTO;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import java.net.URI;
import java.util.List;
import java.util.Map;

/**
 * 在线文档控制器
 */
@RestController
@RequestMapping("/api/online-documents")
@RequiredArgsConstructor
public class OnlineDocumentController {

    private final OnlineDocumentService documentService;

    @Value("${urgs.api-base-url:}")
    private String apiBaseUrl;

    @GetMapping
    public ResponseEntity<PageResult<OnlineDocument>> listDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String fileType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(PageResult.of(documentService.listDocuments(userId, keyword, fileType, page, size)));
    }

    @GetMapping("/favorite")
    public ResponseEntity<PageResult<OnlineDocument>> listFavoriteDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String fileType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(PageResult.of(documentService.listFavoriteDocuments(userId, keyword, fileType, page, size)));
    }

    @GetMapping("/space")
    public ResponseEntity<PageResult<OnlineDocument>> listSpaceDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) String spaceType,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String fileType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(PageResult.of(documentService.listSpaceDocuments(userId, spaceType, keyword, fileType, page, size)));
    }

    @PostMapping("/{id}/favorite")
    public ResponseEntity<OnlineDocument> toggleFavorite(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.toggleFavorite(id, userId));
    }

    @PutMapping("/{id}/space")
    public ResponseEntity<OnlineDocument> setSpaceType(
            HttpServletRequest request,
            @PathVariable Long id,
            @Valid @RequestBody SetOnlineDocumentSpaceTypeRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.setSpaceType(id, userId, req.getSpaceType()));
    }

    @PostMapping
    public ResponseEntity<OnlineDocument> createDocument(
            HttpServletRequest request,
            @Valid @RequestBody CreateOnlineDocumentRequest req) {
        Long userId = getUserId(request);
        OnlineDocument doc = new OnlineDocument();
        doc.setTitle(req.getTitle());
        doc.setFileUrl(req.getFileUrl());
        doc.setFileName(req.getFileName());
        doc.setFileSize(req.getFileSize());
        return ResponseEntity.ok(documentService.createDocument(userId, doc));
    }

    @PostMapping("/blank")
    public ResponseEntity<OnlineDocument> createBlankDocument(
            HttpServletRequest request,
            @Valid @RequestBody CreateBlankOnlineDocumentRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.createBlankDocument(userId, req.getTitle(), req.getDocumentType()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OnlineDocument> updateDocument(
            HttpServletRequest request,
            @PathVariable Long id,
            @Valid @RequestBody UpdateOnlineDocumentRequest req) {
        Long userId = getUserId(request);
        OnlineDocument updates = new OnlineDocument();
        updates.setTitle(req.getTitle());
        updates.setFileName(req.getFileName());
        return ResponseEntity.ok(documentService.updateDocument(id, userId, updates));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteDocument(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        documentService.deleteDocument(id, userId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{id}/permissions")
    public ResponseEntity<List<OnlineDocumentPermissionDTO>> listPermissions(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.listPermissions(id, userId));
    }

    @GetMapping("/permission-users")
    public ResponseEntity<List<UserDTO>> searchPermissionUsers(
            HttpServletRequest request,
            @RequestParam(required = false) String keyword) {
        getUserId(request);
        return ResponseEntity.ok(documentService.searchPermissionUsers(keyword));
    }

    @GetMapping("/permission-groups")
    public ResponseEntity<List<OnlineDocumentPermissionGroupDTO>> listPermissionGroups(HttpServletRequest request) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.listPermissionGroups(userId));
    }

    @PostMapping("/permission-groups")
    public ResponseEntity<OnlineDocumentPermissionGroupDTO> createPermissionGroup(
            HttpServletRequest request,
            @RequestBody OnlineDocumentPermissionGroupRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.createPermissionGroup(userId, req));
    }

    @PutMapping("/permission-groups/{groupId}")
    public ResponseEntity<OnlineDocumentPermissionGroupDTO> updatePermissionGroup(
            HttpServletRequest request,
            @PathVariable Long groupId,
            @RequestBody OnlineDocumentPermissionGroupRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.updatePermissionGroup(userId, groupId, req));
    }

    @DeleteMapping("/permission-groups/{groupId}")
    public ResponseEntity<Void> deletePermissionGroup(
            HttpServletRequest request,
            @PathVariable Long groupId) {
        Long userId = getUserId(request);
        documentService.deletePermissionGroup(userId, groupId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/permissions")
    public ResponseEntity<List<OnlineDocumentPermissionDTO>> savePermissions(
            HttpServletRequest request,
            @PathVariable Long id,
            @RequestBody UpdateOnlineDocumentPermissionsRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.savePermissions(id, userId, req.getUserIds()));
    }

    @GetMapping("/{id}/onlyoffice/config")
    public ResponseEntity<Map<String, Object>> getOnlyOfficeConfig(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        OnlineDocument doc = documentService.getAccessibleDocument(id, userId);
        String fileUrl = toAbsoluteUrl(request, doc.getFileUrl());
        String callbackToken = documentService.buildOnlyOfficeCallbackToken(doc.getId(), doc.getFileUrl());
        String callbackUrl = toAbsoluteUrl(request,
                "/api/online-documents/" + doc.getId() + "/onlyoffice/callback?callbackToken=" + callbackToken);
        return ResponseEntity.ok(documentService.buildOnlyOfficeEditorConfig(id, userId, fileUrl, callbackUrl));
    }

    @PostMapping("/{id}/onlyoffice/callback")
    public ResponseEntity<Map<String, Integer>> handleOnlyOfficeCallback(
            @PathVariable Long id,
            @RequestParam String callbackToken,
            @RequestBody OnlyOfficeCallbackRequest callbackRequest) {
        OnlineDocument doc = documentService.getDocument(id);
        if (!documentService.verifyOnlyOfficeCallbackToken(id, doc.getFileUrl(), callbackToken)) {
            return ResponseEntity.status(403).body(Map.of("error", 1));
        }

        Integer status = callbackRequest.getStatus();
        if ((Integer.valueOf(2).equals(status) || Integer.valueOf(6).equals(status))
                && StringUtils.hasText(callbackRequest.getUrl())) {
            documentService.saveOnlyOfficeDocument(id, callbackRequest.getUrl());
        }
        return ResponseEntity.ok(Map.of("error", 0));
    }

    private Long getUserId(HttpServletRequest request) {
        Object userId = request.getAttribute("userId");
        if (userId == null) {
            throw new UnauthorizedException("用户未登录");
        }
        return Long.valueOf(userId.toString());
    }

    private String toAbsoluteUrl(HttpServletRequest request, String url) {
        if (!StringUtils.hasText(url)) {
            return "";
        }
        try {
            URI uri = URI.create(url);
            if (uri.isAbsolute()) {
                return url;
            }
        } catch (IllegalArgumentException ignored) {
            // 按相对路径处理
        }

        String baseUrl = StringUtils.hasText(apiBaseUrl)
                ? apiBaseUrl
                : request.getScheme() + "://" + request.getServerName()
                        + (isDefaultPort(request) ? "" : ":" + request.getServerPort());
        return baseUrl.replaceAll("/+$", "") + (url.startsWith("/") ? url : "/" + url);
    }

    private boolean isDefaultPort(HttpServletRequest request) {
        return ("http".equals(request.getScheme()) && request.getServerPort() == 80)
                || ("https".equals(request.getScheme()) && request.getServerPort() == 443);
    }
}
