package com.example.executor.quartz.dao;

import com.example.executor.quartz.domain.entity.QuartzTaskLogEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface QuartzTaskLogDao {

    int insertLog(@Param("entity") QuartzTaskLogEntity entity);

    int appendLog(@Param("id") Long id, @Param("line") String line);

    int finishLog(@Param("id") Long id,
                  @Param("processStatus") Integer processStatus,
                  @Param("processDuration") Long processDuration);
}

