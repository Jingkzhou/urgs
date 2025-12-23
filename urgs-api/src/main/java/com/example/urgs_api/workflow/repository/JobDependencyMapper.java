package com.example.urgs_api.workflow.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.workflow.entity.JobDependency;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface JobDependencyMapper extends BaseMapper<JobDependency> {
}
