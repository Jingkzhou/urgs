package com.example.urgs_api.ops.entity;

import com.fasterxml.jackson.annotation.JsonBackReference;
import jakarta.persistence.*;
import lombok.Data;
import lombok.ToString;

import java.time.LocalDateTime;

/**
 * 基础设施资产用户 (账号信息)
 */
@Data
@Entity
@Table(name = "t_infrastructure_user")
public class InfrastructureUser {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    /** 用户名 */
    @Column(nullable = false, length = 100)
    private String username;

    /** 密码 */
    @Column(length = 255)
    private String password;

    /** 说明 */
    @Column(length = 500)
    private String description;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "asset_id", nullable = false)
    @JsonBackReference // Prevent infinite recursion during JSON serialization
    @ToString.Exclude // Prevent circular reference in toString
    private InfrastructureAsset asset;

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
