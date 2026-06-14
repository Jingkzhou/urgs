package com.example.urgs_api.online.controller;

import com.baomidou.mybatisplus.core.metadata.IPage;
import com.example.urgs_api.online.entity.OnlineDocument;
import com.example.urgs_api.online.service.OnlineDocumentService;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import jakarta.servlet.http.HttpServletRequest;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.ResponseEntity;
import org.springframework.util.StringUtils;
import org.springframework.web.bind.annotation.*;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.HashMap;
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
    private final ObjectMapper objectMapper;

    @Value("${urgs.onlyoffice.document-server-url:http://localhost:8088}")
    private String onlyOfficeDocumentServerUrl;

    @Value("${urgs.api-base-url:}")
    private String apiBaseUrl;

    @Value("${urgs.onlyoffice.jwt-secret:}")
    private String onlyOfficeJwtSecret;

    @GetMapping
    public ResponseEntity<IPage<OnlineDocument>> listDocuments(
            HttpServletRequest request,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String fileType,
            @RequestParam(defaultValue = "1") int page,
            @RequestParam(defaultValue = "20") int size) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.listDocuments(userId, keyword, fileType, page, size));
    }

    @PostMapping
    public ResponseEntity<OnlineDocument> createDocument(
            HttpServletRequest request,
            @RequestBody CreateDocumentRequest req) {
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
            @RequestBody CreateBlankDocumentRequest req) {
        Long userId = getUserId(request);
        return ResponseEntity.ok(documentService.createBlankDocument(userId, req.getTitle(), req.getDocumentType()));
    }

    @PutMapping("/{id}")
    public ResponseEntity<OnlineDocument> updateDocument(
            HttpServletRequest request,
            @PathVariable Long id,
            @RequestBody UpdateDocumentRequest req) {
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

    @GetMapping("/{id}/onlyoffice/config")
    public ResponseEntity<Map<String, Object>> getOnlyOfficeConfig(
            HttpServletRequest request,
            @PathVariable Long id) {
        Long userId = getUserId(request);
        OnlineDocument doc = documentService.getAccessibleDocument(id, userId);
        String fileName = doc.getFileName() != null ? doc.getFileName() : doc.getTitle();
        String extension = getFileExtension(fileName);
        String fileUrl = toAbsoluteUrl(request, doc.getFileUrl());
        String callbackToken = documentService.buildOnlyOfficeCallbackToken(doc.getId(), doc.getFileUrl());
        String callbackUrl = toAbsoluteUrl(
                request,
                "/api/online-documents/" + doc.getId() + "/onlyoffice/callback?callbackToken=" + callbackToken);

        Map<String, Object> document = new HashMap<>();
        document.put("fileType", extension);
        document.put("key", "online-" + doc.getId() + "-" + doc.getUpdateTime().toString().replaceAll("[^0-9]", ""));
        document.put("title", fileName);
        document.put("url", fileUrl);
        document.put("permissions", Map.of(
                "download", true,
                "edit", isEditableByOnlyOffice(extension),
                "print", true));

        Map<String, Object> editorConfig = new HashMap<>();
        editorConfig.put("mode", isEditableByOnlyOffice(extension) ? "edit" : "view");
        editorConfig.put("lang", "zh-CN");
        editorConfig.put("callbackUrl", callbackUrl);
        editorConfig.put("user", Map.of(
                "id", String.valueOf(userId),
                "name", "用户" + userId));
        editorConfig.put("customization", Map.of(
                "autosave", true,
                "forcesave", true,
                "compactToolbar", false));

        Map<String, Object> config = new HashMap<>();
        config.put("type", "desktop");
        config.put("documentType", resolveOnlyOfficeDocumentType(extension));
        config.put("document", document);
        config.put("editorConfig", editorConfig);
        config.put("width", "100%");
        config.put("height", "100%");
        if (StringUtils.hasText(onlyOfficeJwtSecret)) {
            config.put("token", buildOnlyOfficeJwt(config));
        }

        return ResponseEntity.ok(Map.of(
                "documentServerUrl", normalizeDocumentServerUrl(),
                "config", config));
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
            throw new RuntimeException("用户未登录");
        }
        return Long.valueOf(userId.toString());
    }

    private String normalizeDocumentServerUrl() {
        return onlyOfficeDocumentServerUrl.replaceAll("/+$", "");
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

    private String getFileExtension(String fileName) {
        if (!StringUtils.hasText(fileName) || !fileName.contains(".")) {
            return "";
        }
        return fileName.substring(fileName.lastIndexOf('.') + 1).toLowerCase();
    }

    private String resolveOnlyOfficeDocumentType(String extension) {
        if (List.of("doc", "docx", "odt", "rtf", "txt").contains(extension)) {
            return "word";
        }
        if (List.of("xls", "xlsx", "ods", "csv").contains(extension)) {
            return "cell";
        }
        if (List.of("ppt", "pptx", "odp").contains(extension)) {
            return "slide";
        }
        if ("pdf".equals(extension)) {
            return "pdf";
        }
        return "word";
    }

    private boolean isEditableByOnlyOffice(String extension) {
        return List.of("docx", "xlsx", "pptx").contains(extension);
    }

    private String buildOnlyOfficeJwt(Map<String, Object> payload) {
        try {
            String headerJson = objectMapper.writeValueAsString(Map.of("alg", "HS256", "typ", "JWT"));
            String payloadJson = objectMapper.writeValueAsString(payload);
            String encodedHeader = base64Url(headerJson.getBytes(StandardCharsets.UTF_8));
            String encodedPayload = base64Url(payloadJson.getBytes(StandardCharsets.UTF_8));
            String signingInput = encodedHeader + "." + encodedPayload;

            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(onlyOfficeJwtSecret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            return signingInput + "." + base64Url(mac.doFinal(signingInput.getBytes(StandardCharsets.UTF_8)));
        } catch (JsonProcessingException e) {
            throw new IllegalStateException("ONLYOFFICE JWT 序列化失败", e);
        } catch (Exception e) {
            throw new IllegalStateException("ONLYOFFICE JWT 签名失败", e);
        }
    }

    private String base64Url(byte[] bytes) {
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    @Data
    public static class CreateDocumentRequest {
        private String title;
        private String fileUrl;
        private String fileName;
        private Long fileSize;
    }

    @Data
    public static class CreateBlankDocumentRequest {
        private String title;
        private String documentType;
    }

    @Data
    public static class UpdateDocumentRequest {
        private String title;
        private String fileName;
    }

    @Data
    @JsonIgnoreProperties(ignoreUnknown = true)
    public static class OnlyOfficeCallbackRequest {
        private Integer status;
        private String url;
        private String key;
        private Object users;
    }
}
