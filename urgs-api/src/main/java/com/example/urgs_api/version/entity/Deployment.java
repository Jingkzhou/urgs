package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 部署记录实体
 */
@Data
@Entity
@Table(name = "t_deployment")
public class Deployment {

    public static final String STATUS_PENDING = "pending";
    public static final String STATUS_DEPLOYING = "deploying";
    public static final String STATUS_SUCCESS = "success";
    public static final String STATUS_FAILED = "failed";
    public static final String STATUS_ROLLBACK = "rollback";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联监管系统ID */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** 关联环境ID */
    @Column(name = "env_id", nullable = false)
    private Long envId;

    /** 关联发布策略ID */
    @Column(name = "strategy_id")
    private Long strategyId;

    /** 关联流水线执行ID */
    @Column(name = "pipeline_run_id")
    private Long pipelineRunId;

    /** 版本号 */
    @Column(length = 50)
    private String version;

    /** 制品地址 */
    @Column(name = "artifact_url", length = 500)
    private String artifactUrl;

    /** 部署状态 */
    @Column(length = 20)
    private String status = STATUS_PENDING;

    /** 部署人ID */
    @Column(name = "deployed_by")
    private Long deployedBy;

    /** 部署时间 */
    @Column(name = "deployed_at")
    private LocalDateTime deployedAt;

    /** 回滚目标版本ID */
    @Column(name = "rollback_to")
    private Long rollbackTo;

    /** 部署日志 */
    @Column(columnDefinition = "TEXT")
    private String logs;

    /** 备注 */
    @Column(length = 500)
    private String remark;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
