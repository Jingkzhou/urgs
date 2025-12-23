package com.example.urgs_api.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.ai.entity.AiChatSession;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AiChatSessionMapper extends BaseMapper<AiChatSession> {
}
