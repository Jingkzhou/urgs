package com.example.urgs_api.datasource.dto;

import lombok.Data;

@Data
public class DataSourcePoolMemberDTO {

    private Long id;
    private Long poolId;
    private Long datasourceId;
    private String datasourceName;
    private String typeName;
    private String typeCode;
    private String category;
    private Integer enabled;
    private Integer weight;
    private Integer maxConcurrency;
    private Integer sortNo;
    private String remark;
}
