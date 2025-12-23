package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.dto.RagQueryRequest;
import com.example.urgs_api.ai.dto.RagQueryResponse;
import com.example.urgs_api.ai.dto.SqlExplainRequest;
import com.example.urgs_api.ai.service.RagService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/rag")
public class RagController {

    @Autowired
    private RagService ragService;

    @PostMapping("/query")
    public ResponseEntity<RagQueryResponse> query(@RequestBody RagQueryRequest request) {
        RagQueryResponse response = ragService.query(request);
        return ResponseEntity.ok(response);
    }

    @PostMapping("/explain")
    public ResponseEntity<Map<String, Object>> explain(@RequestBody SqlExplainRequest request) {
        Map<String, Object> response = ragService.explain(request);
        return ResponseEntity.ok(response);
    }

    @GetMapping("/collections")
    public ResponseEntity<List<Map<String, Object>>> listCollections() {
        return ResponseEntity.ok(ragService.listCollections());
    }

    @GetMapping("/collections/{name}/peek")
    public ResponseEntity<Map<String, Object>> peekCollection(
            @PathVariable String name,
            @RequestParam(required = false, defaultValue = "20") Integer limit) {
        return ResponseEntity.ok(ragService.peekCollection(name, limit));
    }
}
