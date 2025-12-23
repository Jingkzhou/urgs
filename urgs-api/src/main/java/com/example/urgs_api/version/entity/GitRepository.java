package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * Git 仓库配置实体
 * 支持多平台：GitLab、Gitee、GitHub
 */
@Data
@Entity
@Table(name = "t_git_repository")
public class GitRepository {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联监管系统ID (sys_sso_config.id) */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** Git 平台类型：gitlab, gitee, github */
    @Column(nullable = false, length = 20)
    private String platform;

    /** 仓库名称 */
    @Column(nullable = false, length = 200)
    private String name;

    /** 仓库全名 (owner/repo) */
    @Column(name = "full_name", length = 300)
    private String fullName;

    /** 仓库地址 (HTTPS) */
    @Column(name = "clone_url", nullable = false, length = 500)
    private String cloneUrl;

    /** SSH 地址 */
    @Column(name = "ssh_url", length = 500)
    private String sshUrl;

    /** 默认分支 */
    @Column(name = "default_branch", length = 50)
    private String defaultBranch = "master";

    /** 访问令牌（加密存储） */
    @Column(name = "access_token", length = 500)
    private String accessToken;

    /** Webhook Secret */
    @Column(name = "webhook_secret", length = 100)
    private String webhookSecret;

    /** Webhook URL (本系统接收地址) */
    @Column(name = "webhook_url", length = 500)
    private String webhookUrl;

    /** 是否启用 */
    private Boolean enabled = true;

    /** 最后同步时间 */
    @Column(name = "last_synced_at")
    private LocalDateTime lastSyncedAt;

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
