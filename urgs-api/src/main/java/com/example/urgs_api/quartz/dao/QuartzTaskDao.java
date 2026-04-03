package com.example.urgs_api.quartz.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.quartz.domain.dto.QuartzQueryDTO;
import com.example.urgs_api.quartz.domain.dto.QuartzTaskVO;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Component;

import com.example.urgs_api.quartz.domain.dto.QuartzMissedTaskQueryDTO;

import java.util.List;

/**
 * [  ]
 *
 * @author yandanyang
 * @version 1.0
 * @company 1024lab.net
 * @copyright (c) 2018 1024lab.netInc. All rights reserved.
 * @date 2019/4/13 0013 下午 14:35
 * @since JDK1.8
 */
@Mapper
@Component
public interface QuartzTaskDao extends BaseMapper<QuartzTaskEntity> {

    /**
     * 更新任务状态
     * @param taskId
     * @param taskStatus
     */
    void updateStatus(@Param("taskId") Integer taskId,@Param("taskStatus") Integer taskStatus);

    /**
     * 查询列表
     * @param queryDTO
     * @return
     */
    List<QuartzTaskVO> queryList(Page page, @Param("queryDTO")QuartzQueryDTO queryDTO);


    /**
     * 按依赖任务ID查询所有依赖任务
     * @param id
     * @return
     */
    List<QuartzTaskEntity> getTaskListByDepId( @Param("id")Long id);

    List<Long> getPreTaskIdsByTaskId(@Param("taskId") Long taskId);

    void deleteDependenciesByTaskId(@Param("taskId") Long taskId);

    int insertTaskDependency(@Param("taskId") Long taskId, @Param("preTaskId") Long preTaskId);


    void updateJobKey( @Param("taskEntity") QuartzTaskEntity taskEntity);

    List<QuartzTaskEntity> queryAllList();

    /**
     * 查询所有活跃任务（task_status=0）
     */
    List<QuartzTaskEntity> queryActiveTasks();

    /**
     * 查询所有活跃任务（可按名称/系统/主题过滤）
     */
    List<QuartzTaskEntity> queryActiveTasksFiltered(@Param("queryDTO") QuartzMissedTaskQueryDTO queryDTO);
}
