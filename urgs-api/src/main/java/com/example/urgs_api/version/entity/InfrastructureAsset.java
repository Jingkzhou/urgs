package com.example.urgs_api.version.entity;

import jakarta.persistence.*;
import lombok.Data;
import java.time.LocalDateTime;

/**
 * 基础设施资产实体 (服务器/虚拟机)
 */
@Data
@Entity
@Table(name = "t_infrastructure_asset")
public class InfrastructureAsset {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 主机名 */
    @Column(nullable = false, length = 100)
    private String hostname;

    /** 内网 IP 地址 */
    @Column(name = "internal_ip", nullable = false, length = 50)
    private String internalIp;

    /** 公网 IP 地址 */
    @Column(name = "external_ip", length = 50)
    private String externalIp;

    /** 操作系统类型 (Linux, Windows, etc.) */
    @Column(name = "os_type", length = 50)
    private String osType;

    /** 操作系统版本 */
    @Column(name = "os_version", length = 100)
    private String osVersion;

    /** CPU 配置 (例如: 8核) */
    @Column(length = 50)
    private String cpu;

    /** 内存配置 (例如: 16GB) */
    @Column(length = 50)
    private String memory;

    /** 磁盘配置 (例如: 500GB SSD) */
    @Column(length = 100)
    private String disk;

    /** 服务器角色 (app, db, redis, nginx, etc.) */
    @Column(length = 50)
    private String role;

    /** 关联应用系统ID */
    @Column(name = "app_system_id")
    private Long appSystemId;

    /** 关联环境ID */
    @Column(name = "env_id")
    private Long envId;

    /** 环境类型 (测试环境, 生产环境, 自定义) */
    @Column(name = "env_type", length = 50)
    private String envType;

    /** 状态 (active, maintenance, offline) */
    @Column(length = 20)
    private String status = "active";

    /** 备注信息 */
    @Column(columnDefinition = "TEXT")
    private String description;

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
