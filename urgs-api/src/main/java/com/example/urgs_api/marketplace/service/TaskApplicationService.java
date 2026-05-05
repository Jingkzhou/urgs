package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.example.urgs_api.marketplace.dto.TaskApplicationDTO;
import com.example.urgs_api.marketplace.model.TaskApplication;

public interface TaskApplicationService extends IService<TaskApplication> {
    boolean applyForTask(TaskApplicationDTO dto, String applicantId);

    boolean approveApplication(String applicationId, String currentUserId, String reviewComment);

    boolean rejectApplication(String applicationId, String currentUserId, String reviewComment);

    boolean withdrawApplication(String applicationId, String applicantId);

    Page<TaskApplicationDTO> listTaskApplications(Page<TaskApplication> page, String taskId, String currentUserId);

    Page<TaskApplicationDTO> listMyApplications(Page<TaskApplication> page, String applicantId);
}
