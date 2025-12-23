package com.example.urgs_api.org.dto;

import com.example.urgs_api.org.model.Org;

public class OrgDTO {
    private String id;
    private String name;
    private String code;
    private String type;
    private String typeName;
    private String status;
    private String parentId;
    private Integer orderNum;

    public OrgDTO() {
    }

    public OrgDTO(String id, String name, String code, String type, String typeName, String status, String parentId, Integer orderNum) {
        this.id = id;
        this.name = name;
        this.code = code;
        this.type = type;
        this.typeName = typeName;
        this.status = status;
        this.parentId = parentId;
        this.orderNum = orderNum;
    }

    public static OrgDTO fromEntity(Org entity) {
        return new OrgDTO(
                entity.getId() == null ? null : String.valueOf(entity.getId()),
                entity.getName(),
                entity.getCode(),
                entity.getType(),
                entity.getTypeName(),
                entity.getStatus(),
                entity.getParentId(),
                entity.getOrderNum()
        );
    }

    public Org toEntity() {
        Org org = new Org();
        if (this.id != null) {
            try {
                org.setId(Long.parseLong(this.id));
            } catch (NumberFormatException ignored) {
                org.setId(null);
            }
        }
        org.setName(this.name);
        org.setCode(this.code);
        org.setType(this.type);
        org.setTypeName(this.typeName);
        org.setStatus(this.status);
        org.setParentId(this.parentId);
        org.setOrderNum(this.orderNum == null ? 0 : this.orderNum);
        return org;
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

    public Integer getOrderNum() {
        return orderNum;
    }

    public void setOrderNum(Integer orderNum) {
        this.orderNum = orderNum;
    }
}
