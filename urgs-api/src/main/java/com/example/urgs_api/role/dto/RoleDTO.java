package com.example.urgs_api.role.dto;

import com.example.urgs_api.role.model.Role;

public class RoleDTO {
    private String id;
    private String name;
    private String code;
    private String permission;
    private String status;
    private String desc;
    private Integer count;

    public RoleDTO() {
    }

    public RoleDTO(String id, String name, String code, String permission, String status, String desc, Integer count) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.permission = permission;
        this.status = status;
        this.desc = desc;
        this.count = count;
    }

    public static RoleDTO fromEntity(Role entity) {
        return new RoleDTO(
                entity.getId() == null ? null : String.valueOf(entity.getId()),
                entity.getName(),
                entity.getCode(),
                entity.getPermission(),
                entity.getStatus(),
                entity.getRemark(),
                entity.getUserCount()
        );
    }

    public Role toEntity() {
        Role r = new Role();
        if (this.id != null) {
            try {
                r.setId(Long.parseLong(this.id));
            } catch (NumberFormatException ignored) {
                r.setId(null);
            }
        }
        r.setName(this.name);
        r.setCode(this.code);
        r.setPermission(this.permission);
        r.setStatus(this.status);
        r.setRemark(this.desc);
        r.setUserCount(this.count == null ? 0 : this.count);
        return r;
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

    public String getPermission() {
        return permission;
    }

    public void setPermission(String permission) {
        this.permission = permission;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getDesc() {
        return desc;
    }

    public void setDesc(String desc) {
        this.desc = desc;
    }

    public Integer getCount() {
        return count;
    }

    public void setCount(Integer count) {
        this.count = count;
    }
}
