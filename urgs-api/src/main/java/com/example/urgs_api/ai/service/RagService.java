package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.dto.RagQueryRequest;
import com.example.urgs_api.ai.dto.RagQueryResponse;
import com.example.urgs_api.ai.dto.SqlExplainRequest;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.ResponseEntity;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;
import org.springframework.beans.factory.annotation.Autowired;
import com.example.urgs_api.ai.repository.KnowledgeFileRepository;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import org.springframework.scheduling.annotation.Async;

@Service
public class RagService {

    private final String PYTHON_RAG_BASE_URL = "http://localhost:8001/api/rag";
    private final RestTemplate restTemplate = new RestTemplate();

    @Autowired
    private KnowledgeFileRepository fileRepository;

    public RagQueryResponse query(RagQueryRequest request) {
        String url = PYTHON_RAG_BASE_URL + "/query";
        ResponseEntity<RagQueryResponse> response = restTemplate.postForEntity(url, request, RagQueryResponse.class);
        RagQueryResponse body = response.getBody();
        if (body != null && body.getResults() != null) {
            updateHitsAsync(body.getResults());
        }
        return body;
    }

    @Async("aiTaskExecutor")
    public void updateHitsAsync(List<Map<String, Object>> results) {
        Set<String> fileNames = new HashSet<>();
        for (Map<String, Object> res : results) {
            Map<String, Object> metadata = (Map<String, Object>) res.get("metadata");
            if (metadata != null && metadata.containsKey("file_name")) {
                fileNames.add((String) metadata.get("file_name"));
            }
        }

        for (String fileName : fileNames) {
            try {
                // Increment hit_count by 1 for each unique file in results
                fileRepository.update(null, new UpdateWrapper<com.example.urgs_api.ai.entity.KnowledgeFile>()
                        .eq("file_name", fileName)
                        .setSql("hit_count = hit_count + 1"));
            } catch (Exception e) {
                // Non-blocking failure
            }
        }
    }

    public Map<String, Object> explain(SqlExplainRequest request) {
        String url = PYTHON_RAG_BASE_URL + "/sql2text/explain";
        // Assuming python returns dict like {"explanation": ...}
        ResponseEntity<Map> response = restTemplate.postForEntity(url, request, Map.class);
        return response.getBody();
    }

    public List<Map<String, Object>> listCollections() {
        String url = "http://localhost:8001/api/rag/vector-db/collections";
        ResponseEntity<List> response = restTemplate.getForEntity(url, List.class);
        return response.getBody();
    }

    public Map<String, Object> peekCollection(String name, Integer limit) {
        String url = "http://localhost:8001/api/rag/vector-db/collections/" + name + "/peek?limit="
                + (limit != null ? limit : 20);
        ResponseEntity<Map> response = restTemplate.getForEntity(url, Map.class);
        return response.getBody();
    }
}
