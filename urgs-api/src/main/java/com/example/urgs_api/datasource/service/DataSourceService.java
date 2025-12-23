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

@Service
public class DataSourceService extends ServiceImpl<DataSourceConfigMapper, DataSourceConfig> {

    @Autowired
    private DataSourceMetaMapper metaMapper;

    public List<DataSourceMeta> getAllMeta() {
        return metaMapper.selectList(null);
    }

    public List<DataSourceConfig> getAllConfigs() {
        return this.list();
    }
}
