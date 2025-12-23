package com.example.urgs_api.user.dto;

import com.example.urgs_api.user.model.User;

public class UserDTO {
    private String id;
    private String empId;
    private String name;
    private String orgName;
    private String roleName;
    private Long roleId; // New
    private String ssoSystem;
    private String phone;
    private String lastLogin;
    private String status;
    private String avatarUrl;

    public UserDTO() {
    }

    public UserDTO(String id, String empId, String name, String orgName, String roleName, Long roleId, String ssoSystem,
            String phone, String lastLogin, String status, String avatarUrl) {
        this.id = id;
        this.empId = empId;
        this.name = name;
        this.orgName = orgName;
        this.roleName = roleName;
        this.roleId = roleId;
        this.ssoSystem = ssoSystem;
        this.phone = phone;
        this.lastLogin = lastLogin;
        this.status = status;
        this.avatarUrl = avatarUrl;
    }

    public static UserDTO fromEntity(User u) {
        return new UserDTO(
                u.getId() == null ? null : String.valueOf(u.getId()),
                u.getEmpId(),
                u.getName(),
                u.getOrgName(),
                u.getRoleName(),
                u.getRoleId(),
                u.getSsoSystem(),
                u.getPhone(),
                u.getLastLogin(),
                u.getStatus(),
                u.getAvatarUrl());
    }

    public User toEntity() {
        User u = new User();
        if (this.id != null) {
            try {
                u.setId(Long.parseLong(this.id));
            } catch (NumberFormatException ignored) {
                u.setId(null);
            }
        }
        u.setEmpId(this.empId);
        u.setName(this.name);
        u.setOrgName(this.orgName);
        u.setRoleName(this.roleName);
        u.setSsoSystem(this.ssoSystem);
        u.setPhone(this.phone);
        u.setLastLogin(this.lastLogin);
        u.setStatus(this.status);
        u.setAvatarUrl(this.avatarUrl);
        return u;
    }

    public String getAvatarUrl() {
        return avatarUrl;
    }

    public void setAvatarUrl(String avatarUrl) {
        this.avatarUrl = avatarUrl;
    }

    public String getId() {
        return id;
    }

    public void setId(String id) {
        this.id = id;
    }

    public String getEmpId() {
        return empId;
    }

    public void setEmpId(String empId) {
        this.empId = empId;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public String getOrgName() {
        return orgName;
    }

    public void setOrgName(String orgName) {
        this.orgName = orgName;
    }

    public String getRoleName() {
        return roleName;
    }

    public void setRoleName(String roleName) {
        this.roleName = roleName;
    }

    public String getSsoSystem() {
        return ssoSystem;
    }

    public void setSsoSystem(String ssoSystem) {
        this.ssoSystem = ssoSystem;
    }

    public String getPhone() {
        return phone;
    }

    public void setPhone(String phone) {
        this.phone = phone;
    }

    public String getLastLogin() {
        return lastLogin;
    }

    public void setLastLogin(String lastLogin) {
        this.lastLogin = lastLogin;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }
}
