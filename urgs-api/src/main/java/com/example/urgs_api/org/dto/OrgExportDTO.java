package com.example.urgs_api.org.dto;

import com.example.urgs_api.org.model.Org;

public class OrgExportDTO {
    private String id;
    private String name;
    private String code;
    private String type;
    private String typeName;
    private String status;
    private String parentId;
    private String parentCode;
    private String parentName;
    private Integer orderNum;

    public static OrgExportDTO fromEntity(Org entity, Org parent) {
        OrgExportDTO dto = new OrgExportDTO();
        dto.setId(entity.getId() == null ? null : String.valueOf(entity.getId()));
        dto.setName(entity.getName());
        dto.setCode(entity.getCode());
        dto.setType(entity.getType());
        dto.setTypeName(entity.getTypeName());
        dto.setStatus(entity.getStatus());
        dto.setParentId(entity.getParentId());
        dto.setParentCode(parent == null ? null : parent.getCode());
        dto.setParentName(parent == null ? null : parent.getName());
        dto.setOrderNum(entity.getOrderNum());
        return dto;
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

    public String getTypeName() {
        return typeName;
    }

    public void setTypeName(String typeName) {
        this.typeName = typeName;
    }

    public String getStatus() {
        return status;
    }

    public void setStatus(String status) {
        this.status = status;
    }

    public String getParentId() {
        return parentId;
    }

    public void setParentId(String parentId) {
        this.parentId = parentId;
    }

    public String getParentCode() {
        return parentCode;
    }

    public void setParentCode(String parentCode) {
        this.parentCode = parentCode;
    }

    public String getParentName() {
        return parentName;
    }

    public void setParentName(String parentName) {
        this.parentName = parentName;
    }

    public Integer getOrderNum() {
        return orderNum;
    }

    public void setOrderNum(Integer orderNum) {
        this.orderNum = orderNum;
    }
}
