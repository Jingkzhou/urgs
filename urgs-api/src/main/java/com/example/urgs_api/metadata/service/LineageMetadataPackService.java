package com.example.urgs_api.metadata.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.example.urgs_api.metadata.dto.StartEngineRequest;
import com.example.urgs_api.metadata.model.LineageAnalysisRecord;
import com.example.urgs_api.metadata.model.ModelField;
import com.example.urgs_api.metadata.model.ModelTable;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.stereotype.Service;
import org.springframework.util.StringUtils;

import java.nio.file.Files;
import java.nio.file.Path;
import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class LineageMetadataPackService {

    private final ModelTableService modelTableService;
    private final ModelFieldService modelFieldService;
    private final ObjectMapper objectMapper;

    public LineageMetadataPackService(ModelTableService modelTableService, ModelFieldService modelFieldService) {
        this.modelTableService = modelTableService;
        this.modelFieldService = modelFieldService;
        this.objectMapper = new ObjectMapper()
                .registerModule(new JavaTimeModule())
                .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    public LineageMetadataPackResult generate(StartEngineRequest request, LineageAnalysisRecord record, Path workingDir)
            throws Exception {
        if (request == null || request.getPhysicalDataSourceId() == null || !StringUtils.hasText(request.getUser())) {
            return new LineageMetadataPackResult("DISABLED", null, null, 0, 0, null,
                    "physicalDataSourceId or schema is empty");
        }
        if (record == null || !StringUtils.hasText(record.getId())) {
            return new LineageMetadataPackResult("DISABLED", null, null, 0, 0, null,
                    "analysis record is empty");
        }

        String owner = normalizeName(request.getUser());
        LocalDateTime generatedAt = LocalDateTime.now();
        List<ModelTable> tables = modelTableService.list(new LambdaQueryWrapper<ModelTable>()
                .eq(ModelTable::getDataSourceId, request.getPhysicalDataSourceId())
                .eq(ModelTable::getOwner, request.getUser())
                .orderByAsc(ModelTable::getOwner)
                .orderByAsc(ModelTable::getName));

        if (tables.isEmpty() && StringUtils.hasText(owner)) {
            tables = modelTableService.list(new LambdaQueryWrapper<ModelTable>()
                    .eq(ModelTable::getDataSourceId, request.getPhysicalDataSourceId())
                    .apply("UPPER(owner) = {0}", owner)
                    .orderByAsc(ModelTable::getOwner)
                    .orderByAsc(ModelTable::getName));
        }

        List<String> tableIds = tables.stream()
                .map(ModelTable::getId)
                .filter(StringUtils::hasText)
                .toList();
        Map<String, List<ModelField>> fieldsByTableId = new HashMap<>();
        if (!tableIds.isEmpty()) {
            List<ModelField> fields = modelFieldService.list(new LambdaQueryWrapper<ModelField>()
                    .in(ModelField::getTableId, tableIds)
                    .orderByAsc(ModelField::getTableId)
                    .orderByAsc(ModelField::getSortOrder)
                    .orderByAsc(ModelField::getName));
            fieldsByTableId = fields.stream().collect(Collectors.groupingBy(ModelField::getTableId));
        }

        List<Map<String, Object>> tablePayloads = new ArrayList<>();
        int fieldCount = 0;
        for (ModelTable table : tables) {
            List<ModelField> fields = new ArrayList<>(fieldsByTableId.getOrDefault(table.getId(), List.of()));
            fields.sort(Comparator
                    .comparing((ModelField field) -> field.getSortOrder() == null ? Integer.MAX_VALUE : field.getSortOrder())
                    .thenComparing(field -> safeUpper(field.getName())));
            fieldCount += fields.size();

            String tableOwner = StringUtils.hasText(table.getOwner()) ? table.getOwner() : request.getUser();
            Map<String, Object> tableMap = new LinkedHashMap<>();
            tableMap.put("id", table.getId());
            tableMap.put("owner", tableOwner);
            tableMap.put("name", table.getName());
            tableMap.put("qualifiedName", buildQualifiedName(tableOwner, table.getName()));
            tableMap.put("cnName", table.getCnName());
            tableMap.put("fields", fields.stream().map(this::toFieldPayload).toList());
            tablePayloads.add(tableMap);
        }

        Map<String, Object> payload = new LinkedHashMap<>();
        payload.put("packVersion", 1);
        payload.put("recordId", record.getId());
        payload.put("versionId", record.getVersionId());
        payload.put("dataSourceId", request.getPhysicalDataSourceId());
        payload.put("owner", request.getUser());
        payload.put("generatedAt", generatedAt);
        payload.put("tableCount", tablePayloads.size());
        payload.put("fieldCount", fieldCount);
        payload.put("tables", tablePayloads);

        Path packPath = workingDir.resolve("logs")
                .resolve("metadata-packs")
                .resolve(record.getId())
                .resolve("metadata-pack.json")
                .toAbsolutePath()
                .normalize();
        Files.createDirectories(packPath.getParent());
        byte[] bytes = objectMapper.writerWithDefaultPrettyPrinter().writeValueAsBytes(payload);
        Files.write(packPath, bytes);
        String hash = sha256(bytes);
        String status = tablePayloads.isEmpty() ? "EMPTY" : "READY";
        return new LineageMetadataPackResult(status, packPath, hash, tablePayloads.size(), fieldCount, generatedAt, null);
    }

    private Map<String, Object> toFieldPayload(ModelField field) {
        Map<String, Object> fieldMap = new LinkedHashMap<>();
        fieldMap.put("name", field.getName());
        fieldMap.put("type", field.getType());
        fieldMap.put("nullable", field.getNullable());
        fieldMap.put("isPk", field.getIsPk());
        fieldMap.put("sortOrder", field.getSortOrder());
        fieldMap.put("cnName", field.getCnName());
        fieldMap.put("remark", field.getRemark());
        return fieldMap;
    }

    private String buildQualifiedName(String owner, String tableName) {
        String normalizedOwner = normalizeName(owner);
        String normalizedTable = normalizeName(tableName);
        return StringUtils.hasText(normalizedOwner) ? normalizedOwner + "." + normalizedTable : normalizedTable;
    }

    private String normalizeName(String value) {
        return value == null ? "" : value.trim().toUpperCase(Locale.ROOT);
    }

    private String safeUpper(String value) {
        return value == null ? "" : value.toUpperCase(Locale.ROOT);
    }

    private String sha256(byte[] bytes) throws Exception {
        MessageDigest digest = MessageDigest.getInstance("SHA-256");
        byte[] hash = digest.digest(bytes);
        StringBuilder builder = new StringBuilder();
        for (byte b : hash) {
            builder.append(String.format("%02x", b));
        }
        return builder.toString();
    }
}
