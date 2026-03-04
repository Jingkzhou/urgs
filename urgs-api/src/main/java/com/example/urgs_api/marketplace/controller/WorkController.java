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
    public Work createWork(@RequestHeader("X-User-Id") String userId, @RequestBody WorkCreateDTO workCreateDTO) {
        return workService.createWork(workCreateDTO, userId);
    }

    @GetMapping
    public PageResult<Work> listWorks(@RequestHeader("X-User-Id") String userId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        Page<Work> page = new Page<>(current, size);
        Page<Work> resultPage = workService.page(page, new LambdaQueryWrapper<Work>()
                .eq(Work::getPublisherId, userId)
                .orderByDesc(Work::getCreateTime));
        return PageResult.of(resultPage);
    }

    @PutMapping("/{id}/publish")
    public ResponseEntity<Void> publishWork(@RequestHeader("X-User-Id") String userId, @PathVariable String id) {
        workService.publishWork(userId, id);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/cancel")
    public ResponseEntity<Void> cancelWork(@RequestHeader("X-User-Id") String userId, @PathVariable String id) {
        workService.cancelWork(userId, id);
        return ResponseEntity.ok().build();
    }
}
