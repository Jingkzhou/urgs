package com.example.urgs_api.datasource.dto;

import lombok.Data;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Data
public class DataSourcePoolDTO {

    private Long id;
    private String name;
    private String poolType;
    private String strategy;
    private Integer status;
    private String remark;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
    private Integer memberCount;
    private Integer enabledMemberCount;
    private List<DataSourcePoolMemberDTO> members = new ArrayList<>();
}
