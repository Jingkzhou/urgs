package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageRequest;
import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.service.WorkService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/marketplace/works")
public class WorkController {

    @Autowired
    private WorkService workService;

    @PostMapping
    public Work createWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestBody WorkCreateDTO workCreateDTO) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return workService.createWork(workCreateDTO, userId);
    }

    @GetMapping
    public PageResult<Work> listWorks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<Work> page = new Page<>(current, size);
        Page<Work> resultPage = workService.page(page, new LambdaQueryWrapper<Work>()
                .eq(Work::getPublisherId, userId)
                .orderByDesc(Work::getCreateTime));
        return PageResult.of(resultPage);
    }

    @PutMapping("/{id}/publish")
    public ResponseEntity<Void> publishWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workService.publishWork(id, userId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<Void> cancelWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workService.cancelWork(id, userId);
        return ResponseEntity.ok().build();
    }

    private String getEffectiveUserId(String headerUserId, Long attrUserId) {
        if (headerUserId != null && !headerUserId.isEmpty()) {
            return headerUserId;
        }
        if (attrUserId != null) {
            return String.valueOf(attrUserId);
        }
        throw new IllegalArgumentException("Missing user identifier");
    }
}
