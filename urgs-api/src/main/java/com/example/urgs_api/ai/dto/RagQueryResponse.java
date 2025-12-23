package com.example.urgs_api.ai.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class RagQueryResponse {
    private List<Map<String, Object>> results;
}
