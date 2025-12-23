package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 发布记录实体
 */
@Data
@Entity
@Table(name = "t_release_record")
public class ReleaseRecord {

    public static final String STATUS_DRAFT = "draft";
    public static final String STATUS_PENDING = "pending";
    public static final String STATUS_APPROVED = "approved";
    public static final String STATUS_REJECTED = "rejected";
    public static final String STATUS_RELEASED = "released";

    public static final String TYPE_FEATURE = "feature";
    public static final String TYPE_BUGFIX = "bugfix";
    public static final String TYPE_HOTFIX = "hotfix";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联监管系统ID */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** 发布标题 */
    @Column(nullable = false, length = 200)
    private String title;

    /** 版本号 */
    @Column(length = 50)
    private String version;

    /** 发布类型: feature, bugfix, hotfix */
    @Column(name = "release_type", length = 20)
    private String releaseType = TYPE_FEATURE;

    /** 变更说明 */
    @Column(columnDefinition = "TEXT")
    private String description;

    /** 变更内容列表 (JSON) */
    @Column(name = "change_list", columnDefinition = "TEXT")
    private String changeList;

    /** 关联部署记录ID */
    @Column(name = "deployment_id")
    private Long deploymentId;

    /** 状态 */
    @Column(length = 20)
    private String status = STATUS_DRAFT;

    /** 创建人ID */
    @Column(name = "created_by")
    private Long createdBy;

    /** 审批人ID */
    @Column(name = "approved_by")
    private Long approvedBy;

    /** 审批时间 */
    @Column(name = "approved_at")
    private LocalDateTime approvedAt;

    /** 发布时间 */
    @Column(name = "released_at")
    private LocalDateTime releasedAt;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }
}
