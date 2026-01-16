package com.example.urgs_api.ai.controller;

import com.example.urgs_api.ai.entity.KnowledgeBase;
import com.example.urgs_api.ai.service.KnowledgeBaseService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/ai/knowledge")
public class KnowledgeBaseController {

    @Autowired
    private KnowledgeBaseService kbService;

    @GetMapping("/list")
    public List<KnowledgeBase> listKBs() {
        return kbService.listKBs();
    }

    @PostMapping("/create")
    public ResponseEntity<?> createKB(@RequestBody KnowledgeBase kb) {
        KnowledgeBase saved = kbService.createKB(kb);
        return ResponseEntity.ok(Map.of("status", "success", "id", saved.getId()));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteKB(@PathVariable Long id) {
        kbService.deleteKB(id);
        return ResponseEntity.ok(Map.of("status", "success"));
    }

    @PostMapping("/update")
    public ResponseEntity<?> updateKB(@RequestBody KnowledgeBase kb) {
        KnowledgeBase updated = kbService.updateKB(kb);
        return ResponseEntity.ok(Map.of("status", "success", "id", updated.getId()));
    }

    @GetMapping("/files")
    public ResponseEntity<?> listFiles(@RequestParam String kbName) {
        return ResponseEntity.ok(kbService.listFiles(kbName));
    }

    @PostMapping("/files/upload")
    public ResponseEntity<?> uploadFile(@RequestParam("kbName") String kbName,
            @RequestParam("file") MultipartFile file) {
        try {
            kbService.uploadFile(kbName, file);
            return ResponseEntity.ok(Map.of("status", "success"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @DeleteMapping("/files")
    public ResponseEntity<?> deleteFile(@RequestParam String kbName, @RequestParam String fileName) {
        try {
            kbService.deleteFile(kbName, fileName);
            return ResponseEntity.ok(Map.of("status", "success"));
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @PostMapping("/ingest")
    public ResponseEntity<?> triggerIngestion(@RequestParam String kbName,
            @RequestParam(required = false, defaultValue = "false", name = "enable_qa_generation") boolean enableQa) {
        try {
            Map<String, Object> result = kbService.triggerIngestion(kbName, enableQa);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @PostMapping("/files/ingest")
    public ResponseEntity<?> ingestFile(@RequestParam String kbName, @RequestParam String fileName,
            @RequestParam(required = false, defaultValue = "false", name = "enable_qa_generation") boolean enableQa) {
        try {
            Map<String, Object> result = kbService.ingestFile(kbName, fileName, enableQa);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @PostMapping("/files/batch-ingest")
    public ResponseEntity<?> batchIngestFiles(@RequestParam String kbName, @RequestBody List<String> fileNames,
            @RequestParam(required = false, defaultValue = "false", name = "enable_qa_generation") boolean enableQa) {
        try {
            Map<String, Object> result = kbService.ingestFiles(kbName, fileNames, enableQa);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }

    @PostMapping("/reset")
    public ResponseEntity<?> resetKB(@RequestParam String kbName) {
        try {
            Map<String, Object> result = kbService.resetKB(kbName);
            return ResponseEntity.ok(result);
        } catch (Exception e) {
            return ResponseEntity.internalServerError().body(Map.of("status", "error", "message", e.getMessage()));
        }
    }
}
