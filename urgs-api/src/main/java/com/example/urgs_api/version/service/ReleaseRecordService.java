package com.example.urgs_api.version.service;

import com.example.urgs_api.version.entity.ApprovalRecord;
import com.example.urgs_api.version.entity.ReleaseRecord;
import com.example.urgs_api.version.repository.ApprovalRecordRepository;
import com.example.urgs_api.version.repository.ReleaseRecordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Slf4j
@Service
@RequiredArgsConstructor
public class ReleaseRecordService {

    private final ReleaseRecordRepository releaseRepository;
    private final ApprovalRecordRepository approvalRepository;

    // ========== 发布记录 CRUD ==========

    public List<ReleaseRecord> findAll() {
        return releaseRepository.findAll();
    }

    public List<ReleaseRecord> findBySsoId(Long ssoId) {
        return releaseRepository.findBySsoIdOrderByCreatedAtDesc(ssoId);
    }

    public List<ReleaseRecord> findByStatus(String status) {
        return releaseRepository.findByStatusOrderByCreatedAtDesc(status);
    }

    public Optional<ReleaseRecord> findById(Long id) {
        return releaseRepository.findById(id);
    }

    @Transactional
    public ReleaseRecord create(ReleaseRecord record) {
        record.setStatus(ReleaseRecord.STATUS_DRAFT);
        return releaseRepository.save(record);
    }

    @Transactional
    public ReleaseRecord update(Long id, ReleaseRecord record) {
        ReleaseRecord existing = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        // 只有草稿状态才能编辑
        if (!ReleaseRecord.STATUS_DRAFT.equals(existing.getStatus())) {
            throw new IllegalStateException("只有草稿状态的记录才能编辑");
        }

        existing.setTitle(record.getTitle());
        existing.setVersion(record.getVersion());
        existing.setReleaseType(record.getReleaseType());
        existing.setDescription(record.getDescription());
        existing.setChangeList(record.getChangeList());

        return releaseRepository.save(existing);
    }

    @Transactional
    public void delete(Long id) {
        ReleaseRecord existing = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        if (!ReleaseRecord.STATUS_DRAFT.equals(existing.getStatus())) {
            throw new IllegalStateException("只有草稿状态的记录才能删除");
        }

        releaseRepository.deleteById(id);
    }

    // ========== 审批流程 ==========

    /**
     * 提交审批
     */
    @Transactional
    public ReleaseRecord submitForApproval(Long id) {
        ReleaseRecord record = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        if (!ReleaseRecord.STATUS_DRAFT.equals(record.getStatus())) {
            throw new IllegalStateException("只有草稿状态才能提交审批");
        }

        record.setStatus(ReleaseRecord.STATUS_PENDING);
        return releaseRepository.save(record);
    }

    /**
     * 审批通过
     */
    @Transactional
    public ReleaseRecord approve(Long id, Long approverId, String approverName, String comment) {
        ReleaseRecord record = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        if (!ReleaseRecord.STATUS_PENDING.equals(record.getStatus())) {
            throw new IllegalStateException("只有待审批状态才能审批");
        }

        // 创建审批记录
        ApprovalRecord approval = new ApprovalRecord();
        approval.setReleaseId(id);
        approval.setApproverId(approverId);
        approval.setApproverName(approverName);
        approval.setAction(ApprovalRecord.ACTION_APPROVE);
        approval.setComment(comment);
        approvalRepository.save(approval);

        // 更新发布记录状态
        record.setStatus(ReleaseRecord.STATUS_APPROVED);
        record.setApprovedBy(approverId);
        record.setApprovedAt(LocalDateTime.now());

        return releaseRepository.save(record);
    }

    /**
     * 审批拒绝
     */
    @Transactional
    public ReleaseRecord reject(Long id, Long approverId, String approverName, String comment) {
        ReleaseRecord record = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        if (!ReleaseRecord.STATUS_PENDING.equals(record.getStatus())) {
            throw new IllegalStateException("只有待审批状态才能拒绝");
        }

        // 创建审批记录
        ApprovalRecord approval = new ApprovalRecord();
        approval.setReleaseId(id);
        approval.setApproverId(approverId);
        approval.setApproverName(approverName);
        approval.setAction(ApprovalRecord.ACTION_REJECT);
        approval.setComment(comment);
        approvalRepository.save(approval);

        // 更新发布记录状态（打回草稿）
        record.setStatus(ReleaseRecord.STATUS_DRAFT);

        return releaseRepository.save(record);
    }

    /**
     * 标记为已发布
     */
    @Transactional
    public ReleaseRecord markAsReleased(Long id, Long deploymentId) {
        ReleaseRecord record = releaseRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("发布记录不存在: " + id));

        if (!ReleaseRecord.STATUS_APPROVED.equals(record.getStatus())) {
            throw new IllegalStateException("只有已审批状态才能发布");
        }

        record.setStatus(ReleaseRecord.STATUS_RELEASED);
        record.setDeploymentId(deploymentId);
        record.setReleasedAt(LocalDateTime.now());

        return releaseRepository.save(record);
    }

    /**
     * 获取审批历史
     */
    public List<ApprovalRecord> getApprovalHistory(Long releaseId) {
        return approvalRepository.findByReleaseIdOrderByCreatedAtDesc(releaseId);
    }
}
