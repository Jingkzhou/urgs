package com.example.urgs_api.ai.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class RagQueryRequest {
    private String query;
    private Integer k = 4;
    private String collectionName; // Optional, specific single
    @com.fasterxml.jackson.annotation.JsonProperty("collection_names")
    private List<String> collectionNames;
}
