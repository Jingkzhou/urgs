package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 流水线定义实体
 */
@Data
@Entity
@Table(name = "t_pipeline")
public class Pipeline {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 流水线名称 */
    @Column(nullable = false, length = 100)
    private String name;

    /** 关联监管系统ID */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** 关联 Git 仓库ID */
    @Column(name = "repo_id")
    private Long repoId;

    /** 阶段配置 (JSON) */
    @Column(columnDefinition = "JSON")
    private String stages;

    /** 触发类型：manual, webhook, schedule */
    @Column(name = "trigger_type", length = 20)
    private String triggerType = "manual";

    /** 是否启用 */
    private Boolean enabled = true;

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
