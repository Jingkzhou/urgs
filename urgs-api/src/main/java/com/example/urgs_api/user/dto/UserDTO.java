package com.example.urgs_api.user.dto;

import com.example.urgs_api.user.model.User;

public class UserDTO {
    private String id;
    private String empId;
    private String name;
    private String orgName;
    private String roleName;
    private Long roleId; // New
    private String system;
    private String phone;
    private String lastLogin;
    private String status;
    private String avatarUrl;
    private String email;
    private String gitlabUsername;
    private String gitAccessToken;

    public UserDTO() {
    }

    public UserDTO(String id, String empId, String name, String orgName, String roleName, Long roleId, String system,
            String phone, String lastLogin, String status, String avatarUrl, String email, String gitlabUsername,
            String gitAccessToken) {
        this.id = id;
        this.empId = empId;
        this.name = name;
        this.orgName = orgName;
        this.roleName = roleName;
        this.roleId = roleId;
        this.system = system;
        this.phone = phone;
        this.lastLogin = lastLogin;
        this.status = status;
        this.avatarUrl = avatarUrl;
        this.email = email;
        this.gitlabUsername = gitlabUsername;
        this.gitAccessToken = gitAccessToken;
    }

    public static UserDTO fromEntity(User user) {
        if (user == null) {
            return null;
        }
        UserDTO dto = new UserDTO();
        dto.setId(user.getId() == null ? null : String.valueOf(user.getId())); // Convert Long to String for id
        dto.setEmpId(user.getEmpId());
        dto.setName(user.getName());
        dto.setOrgName(user.getOrgName());
        dto.setRoleName(user.getRoleName());
        dto.setRoleId(user.getRoleId());
        dto.setSystem(user.getSystem());
        dto.setPhone(user.getPhone());
        dto.setLastLogin(user.getLastLogin());
        dto.setStatus(user.getStatus());
        dto.setAvatarUrl(user.getAvatarUrl());
        dto.setEmail(user.getEmail());
        dto.setGitlabUsername(user.getGitlabUsername());
        dto.setGitAccessToken(user.getGitAccessToken());
        return dto;
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
        u.setSystem(this.system);
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

    public String getSystem() {
        return system;
    }

    public void setSystem(String system) {
        this.system = system;
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

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getGitlabUsername() {
        return gitlabUsername;
    }

    public void setGitlabUsername(String gitlabUsername) {
        this.gitlabUsername = gitlabUsername;
    }

    public String getGitAccessToken() {
        return gitAccessToken;
    }

    public void setGitAccessToken(String gitAccessToken) {
        this.gitAccessToken = gitAccessToken;
    }

    public Long getRoleId() {
        return roleId;
    }

    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }
}
