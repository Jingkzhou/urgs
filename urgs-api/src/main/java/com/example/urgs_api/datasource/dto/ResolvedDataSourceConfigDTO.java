package com.example.urgs_api.datasource.dto;

import lombok.Data;

import java.util.Map;

@Data
public class ResolvedDataSourceConfigDTO {

    private Long id;
    private String name;
    private Long metaId;
    private String typeName;
    private String typeCode;
    private String category;
    private Integer status;
    private Long appSystemId;
    private Long envId;

    private String url;
    private String username;
    private String password;
    private String driver;
    private String host;
    private Integer port;

    private Map<String, Object> connectionParams;
}
