package com.example.urgs_api.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.ai.entity.AgentRole;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface AgentRoleRepository extends BaseMapper<AgentRole> {
}
