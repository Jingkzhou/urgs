package com.example.urgs_api.metadata.dto;

/**
 * 模型同步请求
 */
public class ModelSyncRequest {
    private Long dataSourceId;
    private String owner;

    public Long getDataSourceId() {
        return dataSourceId;
    }

    public void setDataSourceId(Long dataSourceId) {
        this.dataSourceId = dataSourceId;
    }

    public String getOwner() {
        return owner;
    }

    public void setOwner(String owner) {
        this.owner = owner;
    }
}
