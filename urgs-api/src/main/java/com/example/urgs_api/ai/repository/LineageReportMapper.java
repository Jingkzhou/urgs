package com.example.urgs_api.ai.repository;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.example.urgs_api.ai.entity.LineageReport;
import org.apache.ibatis.annotations.Mapper;

/**
 * 血缘报告 Mapper
 */
@Mapper
public interface LineageReportMapper extends BaseMapper<LineageReport> {
}
