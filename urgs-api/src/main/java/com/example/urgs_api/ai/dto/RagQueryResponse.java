package com.example.urgs_api.ai.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class RagQueryResponse {
    private String answer;
    private Object answer_structured; // Map or Object
    private List<Map<String, Object>> results;
    private List<String> tags;
    private Double confidence;
    private String intent;
}
