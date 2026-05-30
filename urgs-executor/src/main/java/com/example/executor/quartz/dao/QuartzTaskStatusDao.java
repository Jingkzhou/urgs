package com.example.executor.quartz.dao;

import com.example.executor.quartz.domain.entity.QuartzTaskStatusEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface QuartzTaskStatusDao {

    List<QuartzTaskStatusEntity> getWaitingList();

    Integer getStatusByPlanIdAndDate(@Param("planId") Long planId, @Param("dataDate") String dataDate);

    int getFinishCount(@Param("dependIds") List<Long> dependIds, @Param("dataDate") String dataDate);

    int insertStatus(@Param("entity") QuartzTaskStatusEntity entity);

    int resetStatusForDispatch(@Param("entity") QuartzTaskStatusEntity entity);

    int updateStatus(@Param("entity") QuartzTaskStatusEntity entity);
}
