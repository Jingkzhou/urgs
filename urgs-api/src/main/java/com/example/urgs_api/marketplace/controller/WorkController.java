package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.WorkCreateDTO;
import com.example.urgs_api.marketplace.dto.WorkImportDTO;
import com.example.urgs_api.marketplace.dto.WorkStatisticsDTO;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkStatisticsService;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.validation.Valid;
import jakarta.validation.constraints.Size;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.validation.annotation.Validated;
import org.springframework.web.bind.annotation.*;
import org.springframework.util.StringUtils;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;
import java.util.List;
import java.util.Map;

@RestController
@Validated
@RequestMapping("/api/marketplace/works")
public class WorkController {

    @Autowired
    private WorkService workService;

    @Autowired
    private WorkStatisticsService workStatisticsService;

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @PostMapping
    public Work createWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestBody WorkCreateDTO workCreateDTO) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return workService.createWork(workCreateDTO, userId);
    }

    @PutMapping("/{id}")
    public Work updateWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody WorkCreateDTO workCreateDTO) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return workService.updateWork(id, workCreateDTO, userId);
    }

    @PostMapping("/import")
    public Map<String, Integer> importWorks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @Valid @Size(min = 1, max = 500, message = "单次导入数量必须在1到500条之间")
            @RequestBody List<@Valid WorkImportDTO> works) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return Map.of("importedCount", workService.importWorks(works, userId));
    }

    @GetMapping("/{id}")
    public Work getWorkDetail(
            @PathVariable String id) {
        return workService.getById(id);
    }

    @GetMapping
    public PageResult<Work> listWorks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size,
            @RequestParam(required = false) String keyword,
            @RequestParam(required = false) String status,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineStart,
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime deadlineEnd) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        Page<Work> page = new Page<>(current, size);
        LambdaQueryWrapper<Work> query = new LambdaQueryWrapper<>();
        if (!isRegTechAdmin(userId)) {
            query.eq(Work::getPublisherId, userId);
        }
        if (StringUtils.hasText(keyword)) {
            String trimmedKeyword = keyword.trim();
            query.and(wrapper -> wrapper
                    .like(Work::getTitle, trimmedKeyword)
                    .or().like(Work::getRequirementNumber, trimmedKeyword)
                    .or().like(Work::getApplicationDepartment, trimmedKeyword)
                    .or().like(Work::getApplicantName, trimmedKeyword)
                    .or().like(Work::getOwningSystem, trimmedKeyword));
        }
        if (StringUtils.hasText(status)) {
            query.eq(Work::getStatus, status.trim().toUpperCase());
        }
        if (deadlineStart != null) {
            query.ge(Work::getDeadline, deadlineStart);
        }
        if (deadlineEnd != null) {
            query.le(Work::getDeadline, deadlineEnd);
        }
        query.last("ORDER BY "
                + "CASE WHEN status IN ('COMPLETED', 'CANCELLED') THEN 1 ELSE 0 END ASC, "
                + "CASE WHEN status NOT IN ('COMPLETED', 'CANCELLED') AND deadline IS NULL THEN 1 ELSE 0 END ASC, "
                + "CASE WHEN status NOT IN ('COMPLETED', 'CANCELLED') THEN deadline END ASC, "
                + "create_time DESC");
        Page<Work> resultPage = workService.page(page, query);
        return PageResult.of(resultPage);
    }

    private boolean isRegTechAdmin(String userId) {
        try {
            User user = userService.getById(Long.valueOf(userId));
            if (user == null) {
                return false;
            }
            if ("监管科技管理员".equals(user.getRoleName())) {
                return true;
            }
            if (user.getRoleId() == null) {
                return false;
            }
            Role role = roleService.getById(user.getRoleId());
            return role != null && "监管科技管理员".equals(role.getName());
        } catch (NumberFormatException ignored) {
            return false;
        }
    }

    @GetMapping("/statistics")
    public WorkStatisticsDTO getStatistics(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        if (startDate.isAfter(endDate)) {
            throw new IllegalArgumentException("开始日期不能晚于结束日期");
        }
        if (ChronoUnit.DAYS.between(startDate, endDate) > 366) {
            throw new IllegalArgumentException("统计时间范围不能超过366天");
        }
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        String publisherId = isRegTechAdmin(userId) ? null : userId;
        return workStatisticsService.getStatistics(publisherId, startDate, endDate);
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

    @PutMapping("/{id}/pause")
    public ResponseEntity<Void> pauseWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workService.pauseWork(id, resolveAuthorizedPublisherId(id, userId));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/resume")
    public ResponseEntity<Void> resumeWork(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        workService.resumeWork(id, resolveAuthorizedPublisherId(id, userId));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/batch-delete")
    public Map<String, Integer> batchDeleteWorks(
            @RequestHeader(value = "X-User-Id", required = false) String headerUserId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestBody BatchDeleteRequest request) {
        String userId = getEffectiveUserId(headerUserId, attrUserId);
        return Map.of("deletedCount", workService.batchDeleteWorks(request.getIds(), userId));
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

    private String resolveAuthorizedPublisherId(String workId, String userId) {
        Work work = workService.getById(workId);
        return isRegTechAdmin(userId) && work != null ? work.getPublisherId() : userId;
    }

    public static class BatchDeleteRequest {
        private List<String> ids;

        public List<String> getIds() {
            return ids;
        }

        public void setIds(List<String> ids) {
            this.ids = ids;
        }
    }
}
