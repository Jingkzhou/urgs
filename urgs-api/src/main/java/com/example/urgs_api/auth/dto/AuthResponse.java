package com.example.urgs_api.auth.dto;

public class AuthResponse {
    private String token;
    private String id;
    private String empId;
    private String name;
    private String roleName;
    private Long roleId;
    private String ssoSystem;

    public AuthResponse() {
    }

    public AuthResponse(String token, String id, String empId, String name, String roleName, String ssoSystem) {
        this.token = token;
        this.id = id;
        this.empId = empId;
        this.name = name;
        this.roleName = roleName;
        this.ssoSystem = ssoSystem;
    }

    public AuthResponse(String token, String id, String empId, String name, String roleName, Long roleId,
            String ssoSystem) {
        this.token = token;
        this.id = id;
        this.empId = empId;
        this.name = name;
        this.roleName = roleName;
        this.roleId = roleId;
        this.ssoSystem = ssoSystem;
    }

    public Long getRoleId() {
        return roleId;
    }

    public void setRoleId(Long roleId) {
        this.roleId = roleId;
    }

    public String getToken() {
        return token;
    }

    public void setToken(String token) {
        this.token = token;
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
}
