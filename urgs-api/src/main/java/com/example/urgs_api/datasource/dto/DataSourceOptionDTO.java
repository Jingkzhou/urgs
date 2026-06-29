package com.example.urgs_api.datasource.dto;

import lombok.Data;

@Data
public class DataSourceOptionDTO {

    private Long id;
    private String name;
    private Long metaId;
    private Long appSystemId;
    private Long envId;
    private Integer status;
    private String typeName;
    private String typeCode;
    private String category;
}
