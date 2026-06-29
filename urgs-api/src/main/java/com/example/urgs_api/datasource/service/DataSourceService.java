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
        }
        return list;
    }

    public List<DataSourceOptionDTO> getAllOptions() {
        return getAllConfigs().stream().map(config -> {
            DataSourceOptionDTO option = new DataSourceOptionDTO();
            option.setId(config.getId());
            option.setName(config.getName());
            option.setMetaId(config.getMetaId());
            option.setAppSystemId(config.getAppSystemId());
            option.setEnvId(config.getEnvId());
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

}
