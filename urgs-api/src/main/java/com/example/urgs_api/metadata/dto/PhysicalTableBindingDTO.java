package com.example.urgs_api.metadata.dto;

import lombok.Data;

@Data
public class PhysicalTableBindingDTO {
    private String modelTableId;
    private Long dataSourceId;
    private String owner;
    private String tableName;
    private String tableCnName;
}
