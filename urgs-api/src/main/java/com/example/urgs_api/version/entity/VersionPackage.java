package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 版本包记录实体
 * 存储从 Git 仓库归档生成的部署分发包及其关联信息
 */
@Data
@Entity
@Table(name = "t_version_package")
public class VersionPackage {

    public static final String STATUS_DRAFT = "draft";
    public static final String STATUS_READY = "ready";
    public static final String STATUS_DEPLOYED = "deployed";
    public static final String STATUS_ARCHIVED = "archived";
    public static final String STATUS_FAILED = "failed";
    public static final String STATUS_BLOCKED = "blocked";

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 关联 Git 仓库 ID */
    @Column(name = "repo_id", nullable = false)
    private Long repoId;

    /** 关联监管系统 ID */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** 版本号 */
    @Column(nullable = false, length = 50)
    private String version;

    /** Git 引用 (Tag/Branch) */
    @Column(name = "git_ref", length = 100)
    private String gitRef;

    /** Commit SHA */
    @Column(name = "commit_sha", length = 100)
    private String commitSha;

    /** 基线 Git 引用 (上一版本 Tag) */
    @Column(name = "previous_git_ref", length = 100)
    private String previousGitRef;

    /** 基线 Commit SHA */
    @Column(name = "previous_commit_sha", length = 100)
    private String previousCommitSha;

    /** 包名 */
    @Column(name = "package_name", length = 255)
    private String packageName;

    /** 包路径/地址 */
    @Column(name = "package_url", length = 500)
    private String packageUrl;

    /** 文件大小 */
    @Column(name = "package_size")
    private Long packageSize;

    /** 版本说明 */
    @Column(columnDefinition = "TEXT")
    private String description;

    /** 部署脚本内容 */
    @Column(name = "deploy_script", columnDefinition = "TEXT")
    private String deployScript;

    /** 回退脚本内容 */
    @Column(name = "rollback_script", columnDefinition = "TEXT")
    private String rollbackScript;

    /** 状态: draft, ready, deployed, archived */
    @Column(length = 20)
    private String status = STATUS_DRAFT;

    /** 目标数据库服务器资产 ID */
    @Column(name = "asset_id")
    private Long assetId;

    /** 执行用户（数据库用户名） */
    @Column(name = "exec_user", length = 100)
    private String execUser;

    /** 创建人 ID */
    @Column(name = "created_by")
    private Long createdBy;

    /** 部署人 ID */
    @Column(name = "deployed_by")
    private Long deployedBy;

    /** 部署时间 */
    @Column(name = "deployed_at")
    private LocalDateTime deployedAt;

    /** 投产环境ID */
    @Column(name = "env_id")
    private Long envId;

    /** 发布规格文件路径 */
    @Column(name = "spec_path", length = 255)
    private String specPath;

    /** 投产包类型: db/app/static/mixed */
    @Column(name = "package_type", length = 50)
    private String packageType;

    /** 门禁状态 */
    @Column(name = "gate_status", length = 20)
    private String gateStatus;

    /** 门禁摘要(JSON) */
    @Column(name = "gate_summary", columnDefinition = "LONGTEXT")
    private String gateSummary;

    /** 差异文件清单(JSON) */
    @Column(name = "changed_files", columnDefinition = "LONGTEXT")
    private String changedFiles;

    /** 打包日志 */
    @Column(name = "build_log", columnDefinition = "LONGTEXT")
    private String buildLog;

    /** 生产部署命令 */
    @Column(name = "deploy_command", length = 500)
    private String deployCommand;

    /** 生产回滚命令 */
    @Column(name = "rollback_command", length = 500)
    private String rollbackCommand;

    /** 备份状态 */
    @Column(name = "backup_status", length = 20)
    private String backupStatus;

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
