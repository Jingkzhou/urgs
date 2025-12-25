package com.example.urgs_api.datasource.service;

import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.example.urgs_api.datasource.entity.DataSourceConfig;
import com.example.urgs_api.datasource.entity.DataSourceMeta;
import com.example.urgs_api.datasource.repository.DataSourceConfigMapper;
import com.example.urgs_api.datasource.repository.DataSourceMetaMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class DataSourceService extends ServiceImpl<DataSourceConfigMapper, DataSourceConfig> {

    @Autowired
    private DataSourceMetaMapper metaMapper;

    public List<DataSourceMeta> getAllMeta() {
        return metaMapper.selectList(null);
    }

    public List<DataSourceConfig> getAllConfigs() {
        List<DataSourceConfig> list = this.list();
        List<DataSourceMeta> metas = metaMapper.selectList(null);
        Map<Long, String> metaMap = metas.stream()
                .collect(Collectors.toMap(DataSourceMeta::getId, DataSourceMeta::getName));

        for (DataSourceConfig config : list) {
            DataSourceMeta meta = metas.stream().filter(m -> m.getId().equals(config.getMetaId())).findFirst()
                    .orElse(null);

            if (meta != null) {
                config.setTypeName(meta.getName());
                config.setTypeCode(meta.getCode());
                config.setCategory(meta.getCategory());
            }
        }
        return list;
    }
}
