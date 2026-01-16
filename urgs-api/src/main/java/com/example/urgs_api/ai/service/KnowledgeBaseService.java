package com.example.urgs_api.ai.service;

import com.example.urgs_api.ai.entity.KnowledgeBase;
import com.example.urgs_api.ai.entity.KnowledgeFile;
import com.example.urgs_api.ai.repository.KnowledgeBaseRepository;
import com.example.urgs_api.ai.repository.KnowledgeFileRepository;
import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.client.RestTemplate;
import org.springframework.web.util.UriComponentsBuilder;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.stream.Stream;
import org.springframework.scheduling.annotation.Async;

@Service
public class KnowledgeBaseService {

    @Autowired
    private KnowledgeBaseRepository kbRepository;

    @Autowired
    private KnowledgeFileRepository fileRepository;

    @Value("${ai.rag.doc-store-path}")
    private String docStorePath;

    @Value("${ai.rag.base-url}")
    private String pythonRagUrl;
    private final String DEFAULT_EMBEDDING_MODEL = "shibing624/text2vec-base-chinese";

    private final RestTemplate restTemplate = new RestTemplate();

    public List<KnowledgeBase> listKBs() {
        syncExistingKBs();
        return kbRepository.selectList(new QueryWrapper<KnowledgeBase>().orderByDesc("id"));
    }

    private void syncExistingKBs() {
        Path root = Paths.get(docStorePath);
        if (!Files.exists(root))
            return;

        try (Stream<Path> stream = Files.list(root)) {
            stream.filter(Files::isDirectory).forEach(path -> {
                String name = path.getFileName().toString();
                KnowledgeBase existing = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", name));
                if (existing == null) {
                    KnowledgeBase kb = new KnowledgeBase();
                    kb.setName(name);
                    kb.setCollectionName(name);
                    kb.setEmbeddingModel(DEFAULT_EMBEDDING_MODEL);
                    kb.setDescription("Auto-discovered from filesystem");
                    kb.setCreatedAt(new Date());
                    kbRepository.insert(kb);

                    // Sync files for this new KB
                    syncFilesForKB(kb);
                } else {
                    syncFilesForKB(existing);
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    private void syncFilesForKB(KnowledgeBase kb) {
        Path dir = Paths.get(docStorePath, kb.getName());
        if (!Files.exists(dir))
            return;

        try (Stream<Path> stream = Files.list(dir)) {
            stream.filter(f -> !Files.isDirectory(f)).forEach(f -> {
                String fileName = f.getFileName().toString();
                KnowledgeFile existing = fileRepository.selectOne(new QueryWrapper<KnowledgeFile>()
                        .eq("kb_id", kb.getId()).eq("file_name", fileName));
                if (existing == null) {
                    KnowledgeFile kf = new KnowledgeFile();
                    kf.setKbId(kb.getId());
                    kf.setFileName(fileName);
                    try {
                        kf.setFileSize(Files.size(f));
                    } catch (IOException ignored) {
                    }
                    kf.setStatus("UPLOADED");
                    kf.setUploadTime(new Date());
                    fileRepository.insert(kf);
                }
            });
        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public void uploadFile(String kbName, MultipartFile file) throws IOException {
        KnowledgeBase kb = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", kbName));
        if (kb == null)
            throw new RuntimeException("Knowledge Base not found: " + kbName);

        Path uploadDir = Paths.get(docStorePath, kbName);
        if (!Files.exists(uploadDir)) {
            Files.createDirectories(uploadDir);
        }
        String fileName = file.getOriginalFilename();
        Path dest = uploadDir.resolve(fileName);
        file.transferTo(dest);

        // Record in DB
        KnowledgeFile existing = fileRepository.selectOne(new QueryWrapper<KnowledgeFile>()
                .eq("kb_id", kb.getId()).eq("file_name", fileName));
        if (existing == null) {
            KnowledgeFile kf = new KnowledgeFile();
            kf.setKbId(kb.getId());
            kf.setFileName(fileName);
            kf.setFileSize(file.getSize());
            kf.setStatus("UPLOADED");
            kf.setUploadTime(new Date());
            fileRepository.insert(kf);
        } else {
            existing.setFileSize(file.getSize());
            existing.setStatus("UPLOADED"); // Reset status if re-uploaded
            existing.setUploadTime(new Date());
            fileRepository.updateById(existing);
        }
    }

    public List<KnowledgeFile> listFiles(String kbName) {
        KnowledgeBase kb = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", kbName));
        if (kb == null)
            return new ArrayList<>();

        return fileRepository.selectList(new QueryWrapper<KnowledgeFile>()
                .eq("kb_id", kb.getId())
                .eq("is_deleted", 0)
                .orderByDesc("upload_time"));
    }

    public void deleteFile(String kbName, String fileName) throws IOException {
        KnowledgeBase kb = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", kbName));
        if (kb != null) {
            fileRepository.delete(new QueryWrapper<KnowledgeFile>()
                    .eq("kb_id", kb.getId()).eq("file_name", fileName));
        }
        Path file = Paths.get(docStorePath, kbName, fileName);
        Files.deleteIfExists(file);

        // 删除对应的向量切片
        try {
            String url = UriComponentsBuilder.fromHttpUrl(pythonRagUrl + "/delete-file")
                    .queryParam("collection_name", kbName)
                    .queryParam("filename", fileName)
                    .build()
                    .toUriString();
            restTemplate.postForEntity(url, null, Map.class);
        } catch (Exception e) {
            // 向量删除失败不阻断文件删除流程
            e.printStackTrace();
        }
    }

    public KnowledgeBase createKB(KnowledgeBase kb) {
        if (kb.getCollectionName() == null || kb.getCollectionName().isEmpty()) {
            kb.setCollectionName(kb.getName());
        }
        if (kb.getEmbeddingModel() == null || kb.getEmbeddingModel().isEmpty()) {
            kb.setEmbeddingModel(DEFAULT_EMBEDDING_MODEL);
        }
        kb.setCreatedAt(new Date());
        kbRepository.insert(kb);
        return kb;
    }

    public KnowledgeBase updateKB(KnowledgeBase kb) {
        if (kb.getId() == null) {
            throw new RuntimeException("KnowledgeBase ID is required for update");
        }
        KnowledgeBase existing = kbRepository.selectById(kb.getId());
        if (existing == null) {
            throw new RuntimeException("Knowledge Base not found");
        }

        // Only update allowed fields
        if (kb.getDescription() != null)
            existing.setDescription(kb.getDescription());
        if (kb.getEnrichPrompt() != null)
            existing.setEnrichPrompt(kb.getEnrichPrompt());

        // Not allowing name change easily as it affects file paths and collection names
        // (complex migration)
        // If needed, we could support renaming but requires robust file moving logic.

        kbRepository.updateById(existing);
        return existing;
    }

    public void deleteKB(Long id) {
        kbRepository.deleteById(id);
    }

    public Map<String, Object> ingestFiles(String kbName, List<String> fileNames, boolean enableQa) {
        KnowledgeBase kb = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", kbName));
        if (kb == null)
            throw new RuntimeException("Knowledge Base not found");

        List<KnowledgeFile> files = fileRepository.selectList(new QueryWrapper<KnowledgeFile>()
                .eq("kb_id", kb.getId()).in("file_name", fileNames));

        if (files.isEmpty())
            throw new RuntimeException("No file records found");

        // 1. Update all to VECTORIZING
        for (KnowledgeFile file : files) {
            file.setStatus("VECTORIZING");
            file.setErrorMessage(null);
            fileRepository.updateById(file);
        }

        // 2. Start Async process
        performAsyncIngestion(kb, files, fileNames, enableQa);

        Map<String, Object> result = new java.util.HashMap<>();
        result.put("status", "success");
        result.put("message", "Batch ingestion started in background for " + files.size() + " files.");
        return result;
    }

    @Async("aiTaskExecutor")
    public void performAsyncIngestion(KnowledgeBase kb, List<KnowledgeFile> files, List<String> fileNames,
            boolean enableQa) {
        // Sort files by priority (desc) then hit_count (desc)
        List<KnowledgeFile> sortedFiles = files.stream()
                .sorted((a, b) -> {
                    int pComp = Integer.compare(
                            b.getPriority() != null ? b.getPriority() : 0,
                            a.getPriority() != null ? a.getPriority() : 0);
                    if (pComp != 0)
                        return pComp;
                    return Integer.compare(
                            b.getHitCount() != null ? b.getHitCount() : 0,
                            a.getHitCount() != null ? a.getHitCount() : 0);
                })
                .collect(Collectors.toList());

        String kbName = kb.getName();
        for (KnowledgeFile file : sortedFiles) {
            try {
                // Call Python Backend for individual file to track progress more granularly
                String url = UriComponentsBuilder.fromHttpUrl(pythonRagUrl + "/ingest")
                        .queryParam("collection_name", kbName)
                        .queryParam("filenames", file.getFileName())
                        .queryParam("enable_qa_generation", enableQa)
                        .build()
                        .toUriString();
                @SuppressWarnings("rawtypes")
                ResponseEntity<Map> response = restTemplate.postForEntity(url, null, Map.class);
                @SuppressWarnings("unchecked")
                Map<String, Object> body = (Map<String, Object>) response.getBody();

                if (body != null && "success".equals(body.get("status"))) {
                    @SuppressWarnings("unchecked")
                    Map<String, Integer> fileStats = (Map<String, Integer>) body.get("file_stats");
                    UpdateWrapper<KnowledgeFile> uw = new UpdateWrapper<>();
                    uw.eq("id", file.getId())
                            .set("status", "COMPLETED")
                            .set("vector_time", new Date())
                            .setSql("error_message = NULL")
                            .set("chunk_count", (fileStats != null && fileStats.containsKey(file.getFileName()))
                                    ? fileStats.get(file.getFileName())
                                    : 0);
                    fileRepository.update(null, uw);
                } else {
                    file.setStatus("FAILED");
                    file.setErrorMessage(body != null ? (String) body.get("message") : "Ingestion failed");
                    fileRepository.updateById(file);
                }
            } catch (Exception e) {
                file.setStatus("FAILED");
                file.setErrorMessage(e.getMessage());
                fileRepository.updateById(file);
            }
        }
    }

    public Map<String, Object> ingestFile(String kbName, String fileName, boolean enableQa) {
        return ingestFiles(kbName, List.of(fileName), enableQa);
    }

    public Map<String, Object> triggerIngestion(String kbName, boolean enableQa) {
        String url = UriComponentsBuilder.fromHttpUrl(pythonRagUrl + "/ingest")
                .queryParam("collection_name", kbName)
                .queryParam("enable_qa_generation", enableQa)
                .build()
                .toUriString();
        try {
            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.postForEntity(url, null, Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) response.getBody();
            return body;
        } catch (Exception e) {
            e.printStackTrace();
            throw new RuntimeException("Failed to trigger ingestion: " + e.getMessage());
        }
    }

    public Map<String, Object> resetKB(String kbName) {
        KnowledgeBase kb = kbRepository.selectOne(new QueryWrapper<KnowledgeBase>().eq("name", kbName));
        if (kb == null)
            throw new RuntimeException("Knowledge Base not found");

        // 1. Call Python Reset
        String url = UriComponentsBuilder.fromHttpUrl(pythonRagUrl + "/reset")
                .queryParam("collection_name", kbName)
                .build()
                .toUriString();
        try {
            @SuppressWarnings("rawtypes")
            ResponseEntity<Map> response = restTemplate.postForEntity(url, null, Map.class);
            @SuppressWarnings("unchecked")
            Map<String, Object> body = (Map<String, Object>) response.getBody();

            if (body != null && "success".equals(body.get("status"))) {
                // 2. 删除知识库下的文件记录与物理文件
                List<KnowledgeFile> files = fileRepository.selectList(
                        new QueryWrapper<KnowledgeFile>().eq("kb_id", kb.getId()));
                for (KnowledgeFile file : files) {
                    try {
                        Path filePath = Paths.get(docStorePath, kbName, file.getFileName());
                        Files.deleteIfExists(filePath);
                    } catch (Exception e) {
                        e.printStackTrace();
                    }
                }
                fileRepository.delete(new QueryWrapper<KnowledgeFile>().eq("kb_id", kb.getId()));
            }
            return body;
        } catch (Exception e) {
            throw new RuntimeException("Failed to reset knowledge base: " + e.getMessage());
        }
    }
}
