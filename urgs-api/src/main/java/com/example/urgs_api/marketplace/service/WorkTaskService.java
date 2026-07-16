package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.dto.TaskReviewHistoryDTO;
import com.example.urgs_api.marketplace.dto.TaskMarketDTO;
import com.example.urgs_api.marketplace.dto.TaskReviewDTO;
import com.example.urgs_api.marketplace.dto.TaskSubmissionDTO;
import com.example.urgs_api.marketplace.model.WorkTask;

import java.time.LocalDateTime;

public interface WorkTaskService extends IService<WorkTask> {
    Page<TaskMarketDTO> getMarketTasks(Page<WorkTask> page, String keyword, String status);

    Page<TaskMarketDTO> getMyTasks(
            Page<WorkTask> page,
            String userId,
            boolean archived,
            String status,
            boolean overdue,
            LocalDateTime deadlineStart,
            LocalDateTime deadlineEnd);

    Page<TaskMarketDTO> getAssigneeTasks(
            Page<WorkTask> page,
            String userId,
            String status,
            LocalDateTime deadlineStart,
            LocalDateTime deadlineEnd);

    Page<TaskMarketDTO> getReviewTasks(Page<WorkTask> page, String publisherId, boolean history);

    Page<TaskReviewHistoryDTO> getReviewHistory(Page<TaskReviewHistoryDTO> page, String publisherId);

    boolean claimTask(String taskId, String userId);

    boolean releaseTask(String taskId, String userId);

    boolean assignTask(String taskId, String assigneeId, String currentUserId);

    boolean updateTaskStatus(String taskId, String status, String userId);

    boolean reopenTask(String taskId, String userId);

    boolean advanceTaskStage(String taskId, String userId, String assetReviewNote);

    boolean reportTaskStageRisk(String taskId, String riskNote, String userId);

    boolean appendTaskRiskTracking(String taskId, String trackingNote, String userId);

    boolean submitForReview(String taskId, TaskSubmissionDTO dto, String userId);

    boolean reviewTask(String taskId, TaskReviewDTO dto, String reviewerId, String authorizedPublisherId);

    void logTaskAction(String taskId, String operatorId, String action, String detail);

    TaskMarketDTO getTaskDetail(String taskId);
}
