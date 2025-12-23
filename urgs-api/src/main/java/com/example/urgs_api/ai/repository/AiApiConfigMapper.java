package com.example.urgs_api.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.ai.entity.AiApiConfig;
import org.apache.ibatis.annotations.Mapper;

/**
 * AI API 配置 Mapper
 */
@Mapper
public interface AiApiConfigMapper extends BaseMapper<AiApiConfig> {
}
