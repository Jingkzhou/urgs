package com.example.executor.quartz.dao;

import com.example.executor.quartz.domain.entity.QuartzTaskEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

import java.util.List;

@Mapper
public interface QuartzTaskDao {

    QuartzTaskEntity selectById(@Param("id") Long id);

    List<QuartzTaskEntity> queryActiveTasks();

    List<QuartzTaskEntity> getTaskListByDepId(@Param("id") Long id);

    List<Long> getPreTaskIdsByTaskId(@Param("taskId") Long taskId);

    List<QuartzTaskEntity> queryReadyWaitingTasks();
}
