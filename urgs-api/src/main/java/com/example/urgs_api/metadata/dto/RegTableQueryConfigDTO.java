package com.example.urgs_api.metadata.dto;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.Data;

import java.util.ArrayList;
import java.util.List;

@Data
public class RegTableQueryConfigDTO {
    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Long id;

    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Long regTableId;

    private Integer enabled = 0;

    @JsonFormat(shape = JsonFormat.Shape.STRING)
    private Long dataSourceId;

    private String modelTableId;
    private String dateFieldId;
    private String orgCodeFieldId;
    private String orgNameFieldId;
    private List<String> defaultReturnFieldIds = new ArrayList<>();
    private List<String> filterFieldIds = new ArrayList<>();
    private List<String> sortFieldIds = new ArrayList<>();
    private List<String> maskFieldIds = new ArrayList<>();
    private Integer detailMaxRows = 5;
}
