package com.example.urgs_api.ops.entity;

import com.alibaba.excel.annotation.ExcelIgnore;
import com.alibaba.excel.annotation.ExcelProperty;
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

    @OneToMany(mappedBy = "asset", cascade = CascadeType.ALL, orphanRemoval = true, fetch = FetchType.EAGER)
    // Using EAGER for simplicity as there usually won't be many users per asset.
    // If performance issues arise, switch to LAZY and handle loading in Service.
    @com.fasterxml.jackson.annotation.JsonManagedReference
    @ExcelIgnore
    private java.util.List<InfrastructureUser> users = new java.util.ArrayList<>();

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @ExcelProperty("ID (导入时不填)")
    private Long id;

    /** 主机名 */
    @Column(nullable = false, length = 100)
    @ExcelProperty("主机名")
    private String hostname;

    /** 内网 IP 地址 */
    @Column(name = "internal_ip", nullable = false, length = 50)
    @ExcelProperty("内网IP")
    private String internalIp;

    /** 公网 IP 地址 */
    @Column(name = "external_ip", length = 50)
    @ExcelProperty("公网IP")
    private String externalIp;

    /** 操作系统类型 (Linux, Windows, etc.) */
    @Column(name = "os_type", length = 50)
    @ExcelProperty("操作系统")
    private String osType;

    /** 操作系统版本 */
    @Column(name = "os_version", length = 100)
    @ExcelProperty("系统版本")
    private String osVersion;

    /** CPU 配置 (例如: 8核) */
    @Column(length = 50)
    @ExcelProperty("CPU")
    private String cpu;

    /** 内存配置 (例如: 16GB) */
    @Column(length = 50)
    @ExcelProperty("内存")
    private String memory;

    /** 磁盘配置 (例如: 500GB SSD) */
    @Column(length = 100)
    @ExcelProperty("磁盘")
    private String disk;

    /** 硬件型号 (例如: Dell PowerEdge R740) */
    @Column(name = "hardware_model", length = 100)
    @ExcelProperty("硬件型号")
    private String hardwareModel;

    /** 服务器角色 (app, db, redis, nginx, etc.) */
    @Column(length = 50)
    @ExcelProperty("角色")
    private String role;

    /** 关联应用系统ID */
    @Column(name = "app_system_id")
    @ExcelProperty("关联系统ID")
    private Long appSystemId;

    /** 关联环境ID */
    @Column(name = "env_id")
    @ExcelProperty("环境ID")
    private Long envId;

    /** 环境类型 (测试环境, 生产环境, 自定义) */
    @Column(name = "env_type", length = 50)
    @ExcelProperty("环境类型")
    private String envType;

    /** 状态 (active, maintenance, offline) */
    @Column(length = 20)
    @ExcelProperty("状态 (active/maintenance/offline)")
    private String status = "active";

    /** 备注信息 */
    @Column(columnDefinition = "TEXT")
    @ExcelProperty("备注")
    private String description;

    @Column(name = "created_at")
    @ExcelIgnore
    private LocalDateTime createdAt;

    @Column(name = "updated_at")
    @ExcelIgnore
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
