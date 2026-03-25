package com.example.urgs_api.sql.dto;

public class SqlExecuteRequest {
    private String sql;
    private Long dataSourceId;
    private Integer page;
    private Integer pageSize;

    public String getSql() {
        return sql;
    }

    public void setSql(String sql) {
        this.sql = sql;
    }

    public Long getDataSourceId() {
        return dataSourceId;
    }

    public void setDataSourceId(Long dataSourceId) {
        this.dataSourceId = dataSourceId;
    }

    public Integer getPage() {
        return page;
    }

    public void setPage(Integer page) {
        this.page = page;
    }

    public Integer getPageSize() {
        return pageSize;
    }

    public void setPageSize(Integer pageSize) {
        this.pageSize = pageSize;
    }
}
