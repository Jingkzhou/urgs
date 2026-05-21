package com.example.urgs_api.quartz.dao;

import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.quartz.domain.dto.QuartzQueryDTO;
import com.example.urgs_api.quartz.domain.dto.QuartzTaskStatusVO;
import com.example.urgs_api.quartz.domain.dto.QuartzTaskVO;
import com.example.urgs_api.quartz.domain.entity.QuartzTaskStatusEntity;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.springframework.stereotype.Component;

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
public interface QuartzTaskStatusDao extends BaseMapper<QuartzTaskStatusEntity> {


    int getFinishCount(@Param("dependIds") List<Long> dependIds, @Param("dataDate")String dataDate);

    void update(@Param("taskStatusEntity")QuartzTaskStatusEntity taskStatusEntity);

    void delete(@Param("taskId")Long taskId, @Param("dataDate")String dataDate);

    int insert(@Param("taskStatusEntity")QuartzTaskStatusEntity taskStatusEntity);

    List<QuartzTaskStatusVO> queryList(Page page, @Param("queryDTO") QuartzQueryDTO queryDTO);

    List<QuartzTaskVO> queryYlList(Page pageParam, @Param("queryDTO")QuartzQueryDTO queryDTO);
    List<QuartzTaskStatusVO> queryList(@Param("queryDTO") QuartzQueryDTO queryDTO);

    /**
     * 查询所有等待中(status=1)的任务状态记录
     */
    List<QuartzTaskStatusEntity> getWaitingList();

    /**
     * 根据任务ID和数据日期查询当前执行状态
     */
    Integer getStatusByPlanIdAndDate(@Param("planId") Long planId, @Param("dataDate") String dataDate);

    /**
     * 根据任务ID和数据日期查询状态记录
     */
    QuartzTaskStatusEntity selectByPlanIdAndDataDate(@Param("planId") Long planId, @Param("dataDate") String dataDate);

    /**
     * 批量查询日期范围内的状态记录
     */
    List<QuartzTaskStatusEntity> getStatusBatch(@Param("planIds") List<Long> planIds,
                                                 @Param("startDate") String startDate,
                                                 @Param("endDate") String endDate);

    /**
     * 查询任务最近一次成功记录
     */
    QuartzTaskStatusEntity getLastSuccess(@Param("planId") Long planId);

    /**
     * 按实例ID批量查询状态记录
     */
    List<QuartzTaskStatusEntity> selectByIds(@Param("ids") List<Long> ids);

    /**
     * 按实例ID批量更新为等待状态
     */
    int batchResetToWaiting(@Param("ids") List<Long> ids, @Param("msg") String msg);

    /**
     * 按实例ID批量更新为失败状态（强制停止）
     */
    int batchForceStop(@Param("ids") List<Long> ids, @Param("msg") String msg);

    /**
     * 按实例ID批量更新为成功状态（强制通过）
     */
    int batchForcePass(@Param("ids") List<Long> ids, @Param("msg") String msg);

}
