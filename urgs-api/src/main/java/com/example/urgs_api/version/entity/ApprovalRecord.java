package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 审批记录实体
 */
@Data
@Entity
@Table(name = "t_approval_record")
public class ApprovalRecord {

    public static final String ACTION_APPROVE = "approve";
    public static final String ACTION_REJECT = "reject";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联发布记录ID */
    @Column(name = "release_id", nullable = false)
    private Long releaseId;

    /** 审批人ID */
    @Column(name = "approver_id")
    private Long approverId;

    /** 审批人姓名（冗余存储） */
    @Column(name = "approver_name", length = 50)
    private String approverName;

    /** 动作: approve, reject */
    @Column(length = 20)
    private String action;

    /** 审批意见 */
    @Column(length = 500)
    private String comment;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
