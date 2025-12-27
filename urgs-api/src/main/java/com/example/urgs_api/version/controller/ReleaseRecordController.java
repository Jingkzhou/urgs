package com.example.urgs_api.version.controller;

import com.example.urgs_api.version.entity.ApprovalRecord;
import com.example.urgs_api.version.entity.ReleaseRecord;
import com.example.urgs_api.version.service.ReleaseRecordService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/version/releases")
@RequiredArgsConstructor
public class ReleaseRecordController {

    private final ReleaseRecordService releaseService;

    // ========== 发布记录 CRUD ==========

    @GetMapping
    public List<ReleaseRecord> list(@RequestParam(required = false) Long ssoId,
            @RequestParam(required = false) String status) {
        if (ssoId != null) {
            return releaseService.findBySsoId(ssoId);
        }
        if (status != null) {
            return releaseService.findByStatus(status);
        }
        return releaseService.findAll();
    }

    @GetMapping("/{id}")
    public ResponseEntity<ReleaseRecord> getById(@PathVariable Long id) {
        return releaseService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping
    public ReleaseRecord create(@RequestBody ReleaseRecord record) {
        return releaseService.create(record);
    }

    @PutMapping("/{id}")
    public ReleaseRecord update(@PathVariable Long id, @RequestBody ReleaseRecord record) {
        return releaseService.update(id, record);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable Long id) {
        releaseService.delete(id);
        return ResponseEntity.noContent().build();
    }

    @PostMapping("/ai/format-description")
    public ResponseEntity<String> formatDescription(@RequestBody Map<String, String> body) {
        String description = body.get("description");
        return ResponseEntity.ok(releaseService.formatDescription(description));
    }

    // ========== 审批流程 ==========

    /**
     * 提交审批
     */
    @PostMapping("/{id}/submit")
    public ReleaseRecord submitForApproval(@PathVariable Long id) {
        return releaseService.submitForApproval(id);
    }

    /**
     * 审批通过
     */
    @PostMapping("/{id}/approve")
    public ReleaseRecord approve(@PathVariable Long id, @RequestBody Map<String, Object> params) {
        Long approverId = params.get("approverId") != null
                ? Long.valueOf(params.get("approverId").toString())
                : null;
        String approverName = (String) params.get("approverName");
        String comment = (String) params.get("comment");
        return releaseService.approve(id, approverId, approverName, comment);
    }

    /**
     * 审批拒绝
     */
    @PostMapping("/{id}/reject")
    public ReleaseRecord reject(@PathVariable Long id, @RequestBody Map<String, Object> params) {
        Long approverId = params.get("approverId") != null
                ? Long.valueOf(params.get("approverId").toString())
                : null;
        String approverName = (String) params.get("approverName");
        String comment = (String) params.get("comment");
        return releaseService.reject(id, approverId, approverName, comment);
    }

    /**
     * 标记为已发布
     */
    @PostMapping("/{id}/release")
    public ReleaseRecord markAsReleased(@PathVariable Long id,
            @RequestBody(required = false) Map<String, Object> params) {
        Long deploymentId = params != null && params.get("deploymentId") != null
                ? Long.valueOf(params.get("deploymentId").toString())
                : null;
        return releaseService.markAsReleased(id, deploymentId);
    }

    /**
     * 获取审批历史
     */
    @GetMapping("/{id}/approvals")
    public List<ApprovalRecord> getApprovalHistory(@PathVariable Long id) {
        return releaseService.getApprovalHistory(id);
    }
}
