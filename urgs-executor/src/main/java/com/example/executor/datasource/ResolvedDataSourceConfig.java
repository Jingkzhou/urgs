package com.example.executor.datasource;

import lombok.Data;

@Data
public class ResolvedDataSourceConfig {

    private Long id;
    private String name;
    private Long metaId;
    private String typeName;
    private String typeCode;
    private String category;
    private Integer status;
    private String url;
    private String username;
    private String password;
    private String driver;
    private String host;
    private Integer port;
}
