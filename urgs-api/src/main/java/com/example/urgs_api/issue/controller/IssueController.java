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
            @RequestParam(defaultValue = "all") String issueType) {

        Page<Issue> page = new Page<>(current, size);
        Page<Issue> result = issueService.getIssueList(page, keyword, status, issueType);

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

    @GetMapping("/export")
    public void exportData(
            HttpServletResponse response,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "all") String status,
            @RequestParam(defaultValue = "all") String issueType) {
        issueService.exportData(response, keyword, status, issueType);
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
            @RequestParam(defaultValue = "month") String frequency) {
        return ResponseEntity.ok(issueService.getStats(frequency));
    }
}
