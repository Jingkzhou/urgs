package com.example.urgs_api.ai.client;

import com.example.urgs_api.ai.entity.AiApiConfig;
import com.example.urgs_api.ai.service.AiApiConfigService;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.*;
import java.net.HttpURLConnection;
import java.net.URI;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;
import java.util.UUID;

/**
 * Dify API 客户端
 * 处理与 Dify 私有化部署实例的交互
 */
@Component
public class DifyClient {

    private static final Logger log = LoggerFactory.getLogger(DifyClient.class);
    private static final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private AiApiConfigService aiApiConfigService;

    /**
     * 获取 Dify 配置
     */
    private AiApiConfig getDifyConfig() {
        return aiApiConfigService.list().stream()
                .filter(c -> "dify".equalsIgnoreCase(c.getProvider()) && c.getStatus() == 1)
                .findFirst()
                .orElse(null);
    }

    /**
     * 创建数据集 (Dataset)
     */
    public String createDataset(String name, String description, String endpoint, String apiKey) throws Exception {
        String effectiveUrl = getEffectiveUrl(endpoint);
        String effectiveKey = getEffectiveKey(apiKey);

        if (effectiveUrl == null || effectiveKey == null) {
            throw new RuntimeException("Dify API 配置缺失: 请在创建时输入信息或配置系统默认服务");
        }

        String url = normalizeUrl(effectiveUrl) + "datasets";
        Map<String, Object> body = new HashMap<>();
        body.put("name", name);
        body.put("description", description);
        body.put("indexing_technique", "high_quality");
        body.put("permission", "only_me");

        String response = post(url, effectiveKey, objectMapper.writeValueAsString(body));
        JsonNode node = objectMapper.readTree(response);
        return node.get("id").asText();
    }

    public String createDataset(String name, String description) throws Exception {
        return createDataset(name, description, null, null);
    }

    /**
     * 上传并创建文档
     */
    public String uploadDocument(String datasetId, MultipartFile file, String endpoint, String apiKey)
            throws Exception {
        String effectiveUrl = getEffectiveUrl(endpoint);
        String effectiveKey = getEffectiveKey(apiKey);

        if (effectiveUrl == null || effectiveKey == null) {
            throw new RuntimeException("Dify API 配置缺失");
        }

        String url = normalizeUrl(effectiveUrl) + "datasets/" + datasetId + "/document/create_by_file";

        Map<String, String> data = new HashMap<>();
        data.put("indexing_technique", "high_quality");
        data.put("process_rule", "{\"mode\":\"automatic\"}");

        String response = uploadFile(url, effectiveKey, file, data);
        JsonNode node = objectMapper.readTree(response);
        return node.get("document").get("id").asText();
    }

    public String uploadDocument(String datasetId, MultipartFile file) throws Exception {
        return uploadDocument(datasetId, file, null, null);
    }

    /**
     * 知识检索
     */
    public String retrieve(String datasetId, String query, String endpoint, String apiKey) throws Exception {
        String effectiveUrl = getEffectiveUrl(endpoint);
        String effectiveKey = getEffectiveKey(apiKey);

        if (effectiveUrl == null || effectiveKey == null) {
            throw new RuntimeException("Dify API 配置缺失");
        }

        String url = normalizeUrl(effectiveUrl) + "datasets/" + datasetId + "/retrieve";
        Map<String, Object> body = new HashMap<>();
        body.put("query", query);
        body.put("retrieval_model", Map.of("search_method", "hybrid_search", "reranking_enable", true));

        return post(url, effectiveKey, objectMapper.writeValueAsString(body));
    }

    public String retrieve(String datasetId, String query) throws Exception {
        return retrieve(datasetId, query, null, null);
    }

    /**
     * 删除数据集
     */
    public void deleteDataset(String datasetId, String endpoint, String apiKey) throws Exception {
        String effectiveUrl = getEffectiveUrl(endpoint);
        String effectiveKey = getEffectiveKey(apiKey);

        if (effectiveUrl == null || effectiveKey == null) {
            return;
        }

        String url = normalizeUrl(effectiveUrl) + "datasets/" + datasetId;
        delete(url, effectiveKey);
    }

    public void deleteDataset(String datasetId) throws Exception {
        deleteDataset(datasetId, null, null);
    }

    private String getEffectiveUrl(String override) {
        if (override != null && !override.isEmpty())
            return override;
        AiApiConfig config = getDifyConfig();
        if (config != null && config.getEndpoint() != null)
            return config.getEndpoint();
        return System.getenv("DIFY_BASE_URL");
    }

    private String getEffectiveKey(String override) {
        if (override != null && !override.isEmpty())
            return override;
        AiApiConfig config = getDifyConfig();
        if (config != null && config.getApiKey() != null)
            return config.getApiKey();
        return System.getenv("DIFY_API_KEY");
    }

    private String normalizeUrl(String url) {
        if (url == null)
            return "";
        return url.endsWith("/") ? url : url + "/";
    }

    private String post(String url, String apiKey, String jsonBody) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) URI.create(url).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty(HttpHeaders.CONTENT_TYPE, MediaType.APPLICATION_JSON_VALUE);
        conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey);
        conn.setDoOutput(true);

        try (OutputStream os = conn.getOutputStream()) {
            os.write(jsonBody.getBytes(StandardCharsets.UTF_8));
        }

        return readResponse(conn);
    }

    private void delete(String url, String apiKey) throws Exception {
        HttpURLConnection conn = (HttpURLConnection) URI.create(url).toURL().openConnection();
        conn.setRequestMethod("DELETE");
        conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey);
        readResponse(conn);
    }

    private String uploadFile(String url, String apiKey, MultipartFile file, Map<String, String> data)
            throws Exception {
        String boundary = "---" + UUID.randomUUID().toString();
        HttpURLConnection conn = (HttpURLConnection) URI.create(url).toURL().openConnection();
        conn.setRequestMethod("POST");
        conn.setRequestProperty(HttpHeaders.AUTHORIZATION, "Bearer " + apiKey);
        conn.setRequestProperty(HttpHeaders.CONTENT_TYPE, "multipart/form-data; boundary=" + boundary);
        conn.setDoOutput(true);

        try (OutputStream os = conn.getOutputStream();
                PrintWriter writer = new PrintWriter(new OutputStreamWriter(os, StandardCharsets.UTF_8), true)) {

            // 发送表单参数
            for (Map.Entry<String, String> entry : data.entrySet()) {
                writer.append("--").append(boundary).append("\r\n");
                writer.append("Content-Disposition: form-data; name=\"").append(entry.getKey()).append("\"\r\n\r\n");
                writer.append(entry.getValue()).append("\r\n");
            }

            // 发送文件
            writer.append("--").append(boundary).append("\r\n");
            writer.append("Content-Disposition: form-data; name=\"file\"; filename=\"")
                    .append(file.getOriginalFilename()).append("\"\r\n");
            writer.append("Content-Type: ").append(file.getContentType()).append("\r\n\r\n");
            writer.flush();

            try (InputStream is = file.getInputStream()) {
                byte[] buffer = new byte[4096];
                int n;
                while ((n = is.read(buffer)) != -1) {
                    os.write(buffer, 0, n);
                }
            }
            os.write("\r\n".getBytes(StandardCharsets.UTF_8));
            writer.append("--").append(boundary).append("--\r\n");
            writer.flush();
        }

        return readResponse(conn);
    }

    private String readResponse(HttpURLConnection conn) throws Exception {
        int code = conn.getResponseCode();
        InputStream is = (code >= 200 && code < 300) ? conn.getInputStream() : conn.getErrorStream();
        StringBuilder sb = new StringBuilder();
        try (BufferedReader reader = new BufferedReader(new InputStreamReader(is, StandardCharsets.UTF_8))) {
            String line;
            while ((line = reader.readLine()) != null) {
                sb.append(line);
            }
        }
        if (code >= 400) {
            throw new RuntimeException("Dify API Error (" + code + "): " + sb.toString());
        }
        return sb.toString();
    }
}
