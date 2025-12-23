package com.example.urgs_api.permission.dto;

import com.example.urgs_api.permission.model.Permission;

public class PermissionDTO {
    /**
     * Front-end uses string IDs for tree rendering; backend uses DB PK (Long).
     * We keep it as String here and safely parse when needed.
     */
    private String id;
    private String name;
    private String code;
    private String type;
    private String path;
    private Integer level;
    private String parentId;

    public PermissionDTO() {
    }

    public PermissionDTO(String id, String name, String code, String type, String path, Integer level,
            String parentId) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.type = type;
        this.path = path;
        this.level = level;
        this.parentId = parentId;
    }

    public static PermissionDTO fromEntity(Permission entity) {
        return new PermissionDTO(
                entity.getId(),
                entity.getName(),
                entity.getCode(),
                entity.getType(),
                entity.getPath(),
                entity.getLevel(),
                entity.getParentId());
    }

    public Permission toEntity() {
        Permission p = new Permission();
        p.setId(this.id);
        p.setName(this.name);
        p.setCode(this.code);
        p.setType(this.type);
        p.setPath(this.path);
        p.setLevel(this.level);
        p.setParentId(this.parentId);
        return p;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getCode() {
        return code;
    }

    public void setCode(String code) {
        this.code = code;
    }

    public String getType() {
        return type;
    }

    public void setType(String type) {
        this.type = type;
    }

    public String getPath() {
        return path;
    }

    public void setPath(String path) {
        this.path = path;
    }

    public Integer getLevel() {
        return level;
    }

    public void setLevel(Integer level) {
        this.level = level;
    }

    public String getParentId() {
        return parentId;
    }

    public void setParentId(String parentId) {
        this.parentId = parentId;
    }
}
