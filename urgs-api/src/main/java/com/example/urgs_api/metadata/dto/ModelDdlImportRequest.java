package com.example.urgs_api.metadata.dto;

/**
 * 物理模型 DDL 导入请求
 */
public class ModelDdlImportRequest {
    private Long dataSourceId;
    private String owner;
    private String ddl;

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

    public String getDdl() {
        return ddl;
    }

    public void setDdl(String ddl) {
        this.ddl = ddl;
    }
}
