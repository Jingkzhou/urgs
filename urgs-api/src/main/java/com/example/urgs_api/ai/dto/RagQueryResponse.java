package com.example.urgs_api.ai.dto;

import lombok.Data;
import java.util.List;
import java.util.Map;

@Data
public class RagQueryResponse {
    private String answer;
    private Object answer_structured; // Map or Object
    private List<Map<String, Object>> results;
    private List<Map<String, Object>> sources; // Python 返回的是 sources 字段
    private List<String> tags;
    private Double confidence;
    private String intent;

    /**
     * 获取检索结果，优先使用 sources (Python API 返回)，兼容旧的 results 字段
     */
    public List<Map<String, Object>> getEffectiveResults() {
        if (sources != null && !sources.isEmpty()) {
            return sources;
        }
        return results;
    }
}
