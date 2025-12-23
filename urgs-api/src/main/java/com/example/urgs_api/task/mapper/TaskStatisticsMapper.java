package com.example.urgs_api.task.mapper;

import com.example.urgs_api.task.dto.TaskStatsQuery;
import com.example.urgs_api.task.dto.TaskStatsVO;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import java.util.List;

@Mapper
public interface TaskStatisticsMapper {
    List<TaskStatsVO> selectBatchStatusStats(@Param("queryForm") TaskStatsQuery queryForm);
}
