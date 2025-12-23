package com.example.urgs_api.task.service;

import com.example.urgs_api.task.dto.TaskStatsQuery;
import com.example.urgs_api.task.dto.TaskStatsVO;
import com.example.urgs_api.task.mapper.TaskStatisticsMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;

@Service
public class TaskStatisticsService {
    @Autowired
    private TaskStatisticsMapper taskStatisticsMapper;

    public List<TaskStatsVO> getBatchStatusStats(TaskStatsQuery query) {
        return taskStatisticsMapper.selectBatchStatusStats(query);
    }
}
