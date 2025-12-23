package com.example.urgs_api.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.ai.entity.AiUsageLog;
import org.apache.ibatis.annotations.Mapper;

/**
 * AI 使用记录 Mapper
 */
@Mapper
public interface AiUsageLogMapper extends BaseMapper<AiUsageLog> {
}
