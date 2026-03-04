package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.model.WorkTask;

public interface WorkTaskService extends IService<WorkTask> {
    Page<TaskMarketDTO> getMarketTasks(Page<WorkTask> page, String category, String keyword);

    boolean claimTask(String taskId, String userId);

    boolean assignTask(String taskId, String assigneeId, String currentUserId);

    boolean updateTaskStatus(String taskId, String status, String userId);

    void logTaskAction(String taskId, String operatorId, String action, String detail);
}
