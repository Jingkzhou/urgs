package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 部署环境配置实体
 */
@Data
@Entity
@Table(name = "t_deploy_environment")
public class DeployEnvironment {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 环境名称 */
    @Column(nullable = false, length = 50)
    private String name;

    /** 环境编码 (dev/test/staging/prod) */
    @Column(nullable = false, length = 20)
    private String code;

    /** 关联监管系统ID */
    @Column(name = "sso_id", nullable = false)
    private Long ssoId;

    /** 部署目标地址 */
    @Column(name = "deploy_url", length = 500)
    private String deployUrl;

    /** 部署方式: ssh, docker, k8s */
    @Column(name = "deploy_type", length = 20)
    private String deployType = "ssh";

    /** 环境配置参数 (JSON) */
    @Column(columnDefinition = "JSON")
    private String config;

    /** 排序 */
    @Column(name = "sort_order")
    private Integer sortOrder = 0;

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
