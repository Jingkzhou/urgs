package com.example.urgs_api.issue.controller;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.issue.model.Issue;
import com.example.urgs_api.issue.service.IssueService;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.time.LocalDateTime;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.UUID;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import java.net.MalformedURLException;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;

@RestController
@RequestMapping("/api/issue")
public class IssueController {

    @Autowired
    private IssueService issueService;

    @GetMapping("/list")
    public ResponseEntity<PageResult<Issue>> list(
            @RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "10") long size,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "all") String issueType,
            @RequestParam(required = false) String system,
            @RequestParam(required = false) String reporter,
            @RequestParam(required = false) String handler,
            @RequestParam(required = false) String startTime,
            @RequestParam(required = false) String endTime) {

        Page<Issue> page = new Page<>(current, size);
        Page<Issue> result = issueService.getIssueList(page, keyword, status, issueType, system, reporter, handler,
                startTime,
                endTime);

        return ResponseEntity.ok(PageResult.of(result));
    }

    @GetMapping("/{id}")
    public ResponseEntity<Issue> getById(@PathVariable String id) {
        Issue issue = issueService.getById(id);
        if (issue == null) {
            return ResponseEntity.notFound().build();
        }
        return ResponseEntity.ok(issue);
    }

    @PostMapping("/save")
    public ResponseEntity<Issue> save(
            @RequestBody Issue issue,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {

        try {
            String decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
            userId = decodedUserId;
        } catch (Exception e) {
            // ignore
        }

        if (issue.getId() == null || issue.getId().isEmpty()) {
            // New issue
            issue.setCreateTime(LocalDateTime.now());
            issue.setCreateBy(userId);
            if (issue.getStatus() == null || issue.getStatus().isEmpty()) {
                issue.setStatus("新建");
            }
        }
        issue.setUpdateTime(LocalDateTime.now());

        boolean success = issueService.saveOrUpdate(issue);
        if (success) {
            return ResponseEntity.ok(issue);
        } else {
            return ResponseEntity.badRequest().build();
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Boolean> delete(
            @PathVariable String id,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {

        Issue issue = issueService.getById(id);
        if (issue == null) {
            return ResponseEntity.notFound().build();
        }

        boolean success = issueService.removeById(id);
        return ResponseEntity.ok(success);
    }

    @PostMapping("/batch-delete")
    public ResponseEntity<Boolean> deleteBatch(
            @RequestBody java.util.List<String> ids,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {

        if (ids == null || ids.isEmpty()) {
            return ResponseEntity.badRequest().build();
        }

        boolean success = issueService.removeBatchByIds(ids);
        return ResponseEntity.ok(success);
    }

    @GetMapping("/export")
    public void exportData(
            HttpServletResponse response,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "all") String issueType,
            @RequestParam(required = false) String handler) {
        issueService.exportData(response, keyword, status, issueType, handler);
    }

    @PostMapping("/import")
    public ResponseEntity<String> importData(@RequestParam("file") MultipartFile file) {
        try {
            issueService.importData(file);
            return ResponseEntity.ok("导入成功");
        } catch (Exception e) {
            return ResponseEntity.badRequest().body("导入失败: " + e.getMessage());
        }
    }

    @GetMapping("/stats")
    public ResponseEntity<com.example.urgs_api.issue.dto.IssueStatsDTO> getStats(
            @RequestParam(required = false, defaultValue = "month") String frequency,
            @RequestParam(required = false) String startDate,
            @RequestParam(required = false) String endDate) {
        return ResponseEntity.ok(issueService.getStats(frequency, startDate, endDate));
    }

    private static final String UPLOAD_DIR = "/Users/work/Documents/JLbankGit/URGS/attachments";

    @PostMapping("/upload")
    public ResponseEntity<String> uploadAttachment(@RequestParam("file") MultipartFile file) {
        if (file.isEmpty()) {
            return ResponseEntity.badRequest().body("文件为空");
        }

        try {
            File uploadDir = new File(UPLOAD_DIR);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            String originalFilename = file.getOriginalFilename();
            String extension = "";
            if (originalFilename != null && originalFilename.contains(".")) {
                extension = originalFilename.substring(originalFilename.lastIndexOf("."));
            }
            String newFilename = UUID.randomUUID().toString() + extension;
            Path path = Paths.get(UPLOAD_DIR, newFilename);

            Files.write(path, file.getBytes());

            return ResponseEntity.ok(path.toString());
        } catch (IOException e) {
            e.printStackTrace();
            return ResponseEntity.internalServerError().body("上传失败: " + e.getMessage());
        }
    }

    @GetMapping("/download/{id}")
    public ResponseEntity<Resource> downloadAttachment(
            @PathVariable String id,
            @RequestParam(defaultValue = "0") int index) {
        Issue issue = issueService.getById(id);
        if (issue == null || issue.getAttachmentPath() == null) {
            return ResponseEntity.notFound().build();
        }

        try {
            String pathStr = issue.getAttachmentPath();
            String nameStr = issue.getAttachmentName();

            // Try parse as JSON array
            String targetPath = pathStr;
            String targetName = nameStr;

            try {
                if (pathStr.trim().startsWith("[")) {
                    com.fasterxml.jackson.databind.ObjectMapper mapper = new com.fasterxml.jackson.databind.ObjectMapper();
                    java.util.List<String> paths = mapper.readValue(pathStr,
                            new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {
                            });
                    java.util.List<String> names = java.util.Collections.emptyList();
                    if (nameStr != null && nameStr.trim().startsWith("[")) {
                        names = mapper.readValue(nameStr,
                                new com.fasterxml.jackson.core.type.TypeReference<java.util.List<String>>() {
                                });
                    }

                    if (index >= 0 && index < paths.size()) {
                        targetPath = paths.get(index);
                        if (index < names.size()) {
                            targetName = names.get(index);
                        } else {
                            // Fallback name if paths has more entries than names
                            targetName = new File(targetPath).getName();
                        }
                    }
                }
            } catch (Exception e) {
                // Not a JSON array or parse error, treat as single string (backward
                // compatibility)
                // Log if needed, but safe to ignore and use original strings
            }

            if (targetPath == null)
                return ResponseEntity.notFound().build();

            Path filePath = Paths.get(targetPath);
            Resource resource = new UrlResource(filePath.toUri());

            if (resource.exists() || resource.isReadable()) {
                String filename = targetName;
                if (filename == null || filename.isEmpty()) {
                    filename = resource.getFilename();
                }

                String encodedFilename = URLEncoder.encode(filename, StandardCharsets.UTF_8).replace("+", "%20");

                return ResponseEntity.ok()
                        .contentType(MediaType.APPLICATION_OCTET_STREAM)
                        .header(HttpHeaders.CONTENT_DISPOSITION,
                                "attachment; filename=\"" + encodedFilename + "\"; filename*=UTF-8''" + encodedFilename)
                        .body(resource);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (MalformedURLException e) {
            return ResponseEntity.internalServerError().build();
        }
    }
}
