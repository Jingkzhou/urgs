package com.example.urgs_api.datasource.service;

import com.example.urgs_api.datasource.dto.DataSourceOptionDTO;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.test.util.ReflectionTestUtils;

import java.util.List;
import java.util.Map;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertSame;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class DataSourceServiceTest {

    @Test
    void optionsDoNotSerializeConnectionCredentials() throws Exception {
        DataSourceConfigMapper configMapper = mock(DataSourceConfigMapper.class);
        DataSourceMetaMapper metaMapper = mock(DataSourceMetaMapper.class);
        DataSourceService service = new DataSourceService();
        ReflectionTestUtils.setField(service, "baseMapper", configMapper);
        ReflectionTestUtils.setField(service, "metaMapper", metaMapper);

        DataSourceConfig config = new DataSourceConfig();
        config.setId(7L);
        config.setName("reporting-db");
        config.setMetaId(3L);
        config.setStatus(1);
        DataSourceMeta meta = new DataSourceMeta();
        meta.setId(3L);
        meta.setName("MySQL");
        meta.setCode("mysql");
        meta.setCategory("RDBMS");
        meta.setFormSchema(List.of(Map.of("name", "accessKey", "type", "password")));
        config.setConnectionParams(Map.of(
                "username", "reporter",
                "password", "secret",
                "accessKey", "access-secret"));

        when(configMapper.selectList(any())).thenReturn(List.of(config));
        when(metaMapper.selectList(null)).thenReturn(List.of(meta));

        List<DataSourceConfig> configs = service.getAllConfigs();

        assertEquals("reporter", configs.get(0).getConnectionParams().get("username"));
        assertEquals(DataSourceService.MASKED_SECRET, configs.get(0).getConnectionParams().get("password"));
        assertEquals(DataSourceService.MASKED_SECRET, configs.get(0).getConnectionParams().get("accessKey"));

        List<DataSourceOptionDTO> options = service.getAllOptions();

        assertEquals(1, options.size());
        assertEquals("mysql", options.get(0).getTypeCode());
        String json = new ObjectMapper().writeValueAsString(options.get(0));
        assertFalse(json.contains("connectionParams"));
        assertFalse(json.contains("secret"));
        assertFalse(json.contains("password"));
    }

    @Test
    void restoresMaskedSecretsBeforeUpdateOrConnectionTest() {
        DataSourceConfigMapper configMapper = mock(DataSourceConfigMapper.class);
        DataSourceService service = new DataSourceService();
        ReflectionTestUtils.setField(service, "baseMapper", configMapper);

        DataSourceConfig existing = new DataSourceConfig();
        existing.setId(7L);
        existing.setConnectionParams(Map.of("host", "db.internal", "password", "real-secret"));
        when(configMapper.selectById(7L)).thenReturn(existing);

        DataSourceConfig submitted = new DataSourceConfig();
        submitted.setId(7L);
        submitted.setConnectionParams(Map.of("host", "db-new.internal", "password", DataSourceService.MASKED_SECRET));

        DataSourceConfig restored = service.restoreMaskedSecrets(submitted);

        assertSame(submitted, restored);
        assertEquals("db-new.internal", restored.getConnectionParams().get("host"));
        assertEquals("real-secret", restored.getConnectionParams().get("password"));
    }
}
