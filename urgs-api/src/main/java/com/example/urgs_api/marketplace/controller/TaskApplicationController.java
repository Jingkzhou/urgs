package com.example.urgs_api.marketplace.controller;

import com.example.urgs_api.common.PageResult;
import com.example.urgs_api.marketplace.dto.TaskApplicationDTO;
import com.example.urgs_api.marketplace.model.TaskApplication;
import com.example.urgs_api.marketplace.model.Work;
import com.example.urgs_api.marketplace.model.WorkTask;
import com.example.urgs_api.marketplace.service.TaskApplicationService;
import com.example.urgs_api.marketplace.service.WorkService;
import com.example.urgs_api.marketplace.service.WorkTaskService;
import com.example.urgs_api.role.model.Role;
import com.example.urgs_api.role.service.RoleService;
import com.example.urgs_api.user.model.User;
import com.example.urgs_api.user.service.UserService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/api/marketplace/applications")
public class TaskApplicationController {

    @Autowired
    private TaskApplicationService taskApplicationService;

    @Autowired
    private WorkTaskService workTaskService;

    @Autowired
    private WorkService workService;

    @Autowired
    private UserService userService;

    @Autowired
    private RoleService roleService;

    @PostMapping("/apply")
    public ResponseEntity<Void> applyForTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerApplicantId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestBody TaskApplicationDTO body) {
        String applicantId = getEffectiveUserId(headerApplicantId, attrUserId);
        taskApplicationService.applyForTask(body, applicantId);
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/approve")
    public ResponseEntity<Void> approveApplication(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        String userId = getEffectiveUserId(headerPublisherId, attrUserId);
        String publisherId = resolveAuthorizedPublisherIdByApplication(id, userId);
        taskApplicationService.approveApplication(id, publisherId, body == null ? null : body.get("reviewComment"));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/reject")
    public ResponseEntity<Void> rejectApplication(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id,
            @RequestBody(required = false) Map<String, String> body) {
        String userId = getEffectiveUserId(headerPublisherId, attrUserId);
        String publisherId = resolveAuthorizedPublisherIdByApplication(id, userId);
        taskApplicationService.rejectApplication(id, publisherId, body == null ? null : body.get("reviewComment"));
        return ResponseEntity.ok().build();
    }

    @PutMapping("/{id}/withdraw")
    public ResponseEntity<Void> withdrawApplication(
            @RequestHeader(value = "X-User-Id", required = false) String headerApplicantId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String id) {
        String applicantId = getEffectiveUserId(headerApplicantId, attrUserId);
        taskApplicationService.withdrawApplication(id, applicantId);
        return ResponseEntity.ok().build();
    }

    @GetMapping("/task/{taskId}")
    public PageResult<TaskApplicationDTO> getApplicationsByTask(
            @RequestHeader(value = "X-User-Id", required = false) String headerPublisherId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @PathVariable String taskId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        String userId = getEffectiveUserId(headerPublisherId, attrUserId);
        String publisherId = resolveAuthorizedPublisherIdByTask(taskId, userId);
        Page<TaskApplication> page = new Page<>(current, size);
        Page<TaskApplicationDTO> resultPage = taskApplicationService.listTaskApplications(page, taskId, publisherId);
        return PageResult.of(resultPage);
    }

    @GetMapping("/my")
    public PageResult<TaskApplicationDTO> getMyApplications(
            @RequestHeader(value = "X-User-Id", required = false) String headerApplicantId,
            @RequestAttribute(value = "userId", required = false) Long attrUserId,
            @RequestParam(defaultValue = "1") int current,
            @RequestParam(defaultValue = "10") int size) {
        String applicantId = getEffectiveUserId(headerApplicantId, attrUserId);
        Page<TaskApplication> page = new Page<>(current, size);
        Page<TaskApplicationDTO> resultPage = taskApplicationService.listMyApplications(page, applicantId);
        return PageResult.of(resultPage);
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

    private String resolveAuthorizedPublisherIdByApplication(String applicationId, String userId) {
        TaskApplication application = taskApplicationService.getById(applicationId);
        if (application == null) {
            return userId;
        }
        return resolveAuthorizedPublisherIdByTask(application.getTaskId(), userId);
    }

    private String resolveAuthorizedPublisherIdByTask(String taskId, String userId) {
        WorkTask task = workTaskService.getById(taskId);
        if (!isRegTechAdmin(userId) || task == null) {
            return userId;
        }
        Work work = workService.getById(task.getWorkId());
        return work != null ? work.getPublisherId() : userId;
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
}
