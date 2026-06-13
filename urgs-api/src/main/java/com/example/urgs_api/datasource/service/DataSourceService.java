package com.example.urgs_api.datasource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.dto.DataSourceOptionDTO;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.stream.Collectors;

@Service
public class DataSourceService extends ServiceImpl<DataSourceConfigMapper, DataSourceConfig> {

    public static final String MASKED_SECRET = "******";

    @Autowired
    private DataSourceMetaMapper metaMapper;

    public List<DataSourceMeta> getAllMeta() {
        return metaMapper.selectList(null);
    }

    public List<DataSourceConfig> getAllConfigs() {
        List<DataSourceConfig> list = this.list();
        List<DataSourceMeta> metas = metaMapper.selectList(null);
        Map<Long, DataSourceMeta> metaMap = metas.stream()
                .collect(Collectors.toMap(DataSourceMeta::getId, meta -> meta));

        for (DataSourceConfig config : list) {
            DataSourceMeta meta = metaMap.get(config.getMetaId());

            if (meta != null) {
                config.setTypeName(meta.getName());
                config.setTypeCode(meta.getCode());
                config.setCategory(meta.getCategory());
            }
            config.setConnectionParams(maskSensitiveParams(config.getConnectionParams(), meta));
        }
        return list;
    }

    public List<DataSourceOptionDTO> getAllOptions() {
        return getAllConfigs().stream().map(config -> {
            DataSourceOptionDTO option = new DataSourceOptionDTO();
            option.setId(config.getId());
            option.setName(config.getName());
            option.setMetaId(config.getMetaId());
            option.setStatus(config.getStatus());
            option.setTypeName(config.getTypeName());
            option.setTypeCode(config.getTypeCode());
            option.setCategory(config.getCategory());
            return option;
        }).toList();
    }

    public DataSourceConfig restoreMaskedSecrets(DataSourceConfig config) {
        if (config == null || config.getId() == null || config.getConnectionParams() == null) {
            return config;
        }

        DataSourceConfig existing = getById(config.getId());
        if (existing == null) {
            throw new IllegalArgumentException("DataSource not found: " + config.getId());
        }

        Map<String, Object> existingParams = existing.getConnectionParams();
        Map<String, Object> restoredParams = new LinkedHashMap<>(config.getConnectionParams());
        restoredParams.replaceAll((key, value) -> MASKED_SECRET.equals(value) && existingParams != null
                ? existingParams.get(key)
                : value);
        config.setConnectionParams(restoredParams);
        return config;
    }

    public boolean updateConfig(Long id, DataSourceConfig config) {
        config.setId(id);
        return updateById(restoreMaskedSecrets(config));
    }

    private Map<String, Object> maskSensitiveParams(Map<String, Object> params, DataSourceMeta meta) {
        if (params == null) {
            return null;
        }

        Set<String> sensitiveFields = meta == null || meta.getFormSchema() == null
                ? Set.of()
                : meta.getFormSchema().stream()
                        .filter(field -> "password".equalsIgnoreCase(String.valueOf(field.get("type"))))
                        .map(field -> String.valueOf(field.get("name")))
                        .collect(Collectors.toSet());
        Map<String, Object> masked = new LinkedHashMap<>(params);
        masked.replaceAll((key, value) -> sensitiveFields.contains(key) || isSensitiveKey(key)
                ? MASKED_SECRET
                : value);
        return masked;
    }

    private boolean isSensitiveKey(String key) {
        String normalized = key == null ? "" : key.replace("_", "").replace("-", "").toLowerCase();
        return normalized.contains("password")
                || normalized.contains("secret")
                || normalized.contains("token")
                || normalized.equals("accesskey")
                || normalized.equals("apikey")
                || normalized.equals("privatekey");
    }
}
