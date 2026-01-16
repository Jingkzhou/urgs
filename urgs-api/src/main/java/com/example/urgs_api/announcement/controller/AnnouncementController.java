package com.example.urgs_api.announcement.controller;

import com.example.urgs_api.announcement.dto.AnnouncementRequest;
import com.example.urgs_api.announcement.model.Announcement;
import com.example.urgs_api.announcement.model.AnnouncementComment;
import com.example.urgs_api.announcement.service.AnnouncementService;
import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.announcement.dto.AnnouncementQuery;
import com.example.urgs_api.common.PageResult;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/announcement")
public class AnnouncementController {

    @Autowired
    private AnnouncementService announcementService;

    @Autowired
    private ObjectMapper objectMapper;

    @PostMapping("/publish")
    public ResponseEntity<Boolean> publish(@RequestBody AnnouncementRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {
        Announcement announcement = new Announcement();
        announcement.setTitle(request.getTitle());
        announcement.setType(request.getType());
        announcement.setCategory(request.getCategory());
        announcement.setContent(request.getContent());
        announcement.setCreateTime(LocalDateTime.now());
        announcement.setStatus(1); // Published

        try {
            String decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
            announcement.setCreateBy(decodedUserId);
        } catch (Exception e) {
            announcement.setCreateBy(userId);
        }

        try {
            if (request.getAttachments() != null) {
                announcement.setAttachments(objectMapper.writeValueAsString(request.getAttachments()));
            }
            if (request.getSystems() != null) {
                announcement.setSystems(objectMapper.writeValueAsString(request.getSystems()));
            }
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(false);
        }

        boolean success = announcementService.save(announcement);
        return ResponseEntity.ok(success);
    }

    @PutMapping("/update")
    public ResponseEntity<Boolean> update(@RequestBody AnnouncementRequest request,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {
        if (request.getId() == null) {
            return ResponseEntity.badRequest().body(false);
        }
        Announcement announcement = announcementService.getById(request.getId());
        if (announcement == null) {
            return ResponseEntity.notFound().build();
        }

        String decodedUserId = userId;
        try {
            decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            // ignore
        }

        if (!decodedUserId.equals(announcement.getCreateBy())) {
            return ResponseEntity.status(403).body(false);
        }

        announcement.setTitle(request.getTitle());
        announcement.setType(request.getType());
        announcement.setCategory(request.getCategory());
        announcement.setContent(request.getContent());
        announcement.setUpdateTime(LocalDateTime.now());

        try {
            if (request.getAttachments() != null) {
                announcement.setAttachments(objectMapper.writeValueAsString(request.getAttachments()));
            } else {
                announcement.setAttachments("[]");
            }
            if (request.getSystems() != null) {
                announcement.setSystems(objectMapper.writeValueAsString(request.getSystems()));
            } else {
                announcement.setSystems("[]");
            }
        } catch (JsonProcessingException e) {
            e.printStackTrace();
            return ResponseEntity.badRequest().body(false);
        }

        boolean success = announcementService.updateById(announcement);
        return ResponseEntity.ok(success);
    }

    @GetMapping("/list")
    public ResponseEntity<PageResult<Announcement>> list(@RequestParam(defaultValue = "1") long current,
            @RequestParam(defaultValue = "10") long size,
            @RequestParam(required = false) String keyword,
            @RequestParam(defaultValue = "all") String type,
            @RequestParam(required = false) String category,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId,
            @RequestHeader(value = "X-User-Systems", required = false) String userSystemsStr) {

        // In a real app, userId and systems would come from specific SecurityContext or
        // parsed Token
        // Here we simulate getting them from headers or token parsing logic upstream

        AnnouncementQuery query = new AnnouncementQuery();
        query.setKeyword(keyword);
        query.setType(type);
        query.setCategory(category);
        query.setUserId(userId);

        if (userSystemsStr != null && !userSystemsStr.isEmpty()) {
            try {
                String decodedSystems = java.net.URLDecoder.decode(userSystemsStr,
                        java.nio.charset.StandardCharsets.UTF_8);
                query.setUserSystems(java.util.Arrays.asList(decodedSystems.split(",")));
            } catch (Exception e) {
                e.printStackTrace();
                // Fallback or ignore
            }
        }

        if (userId != null && !userId.isEmpty()) {
            try {
                String decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
                query.setUserId(decodedUserId);
            } catch (Exception e) {
                query.setUserId(userId);
            }
        } else {
            query.setUserId(userId);
        }

        Page<Announcement> page = new Page<>(current, size);
        Page<Announcement> result = announcementService.getAnnouncementList(page, query);

        return ResponseEntity.ok(PageResult.of(result));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Boolean> delete(@PathVariable String id,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {
        Announcement announcement = announcementService.getById(id);
        if (announcement == null) {
            return ResponseEntity.notFound().build();
        }

        // Permission check: only creator can delete
        String decodedUserId = userId;
        try {
            decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            // ignore
        }

        if (!decodedUserId.equals(announcement.getCreateBy())) {
            return ResponseEntity.status(403).body(false);
        }

        boolean success = announcementService.removeById(id);
        return ResponseEntity.ok(success);
    }

    @GetMapping("/{id}")
    public ResponseEntity<Announcement> getById(@PathVariable String id) {
        Announcement announcement = announcementService.getById(id);
        return ResponseEntity.ok(announcement);
    }

    @PostMapping("/{id}/read")
    public ResponseEntity<Void> markAsRead(@PathVariable String id,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {
        String decodedUserId = userId;
        try {
            decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            // ignore
        }
        announcementService.markAsRead(id, decodedUserId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{id}/comments")
    public ResponseEntity<List<AnnouncementComment>> getComments(@PathVariable String id) {
        return ResponseEntity.ok(announcementService.getComments(id));
    }

    @PostMapping("/{id}/comments")
    public ResponseEntity<Void> addComment(@PathVariable String id,
            @RequestBody AnnouncementComment comment,
            @RequestHeader(value = "X-User-Id", defaultValue = "admin") String userId) {
        comment.setAnnouncementId(id);

        String decodedUserId = userId;
        try {
            decodedUserId = java.net.URLDecoder.decode(userId, java.nio.charset.StandardCharsets.UTF_8);
        } catch (Exception e) {
            // ignore
        }
        comment.setUserId(decodedUserId);

        announcementService.addComment(comment);
        return ResponseEntity.ok().build();
    }
}
