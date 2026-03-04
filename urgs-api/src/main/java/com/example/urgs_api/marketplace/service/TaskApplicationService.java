package com.example.urgs_api.marketplace.service;

import com.baomidou.mybatisplus.extension.service.IService;
import com.example.urgs_api.marketplace.model.TaskApplication;

public interface TaskApplicationService extends IService<TaskApplication> {
    boolean applyForTask(String taskId, String applicantId, String message);

    boolean approveApplication(String applicationId, String currentUserId);

    boolean rejectApplication(String applicationId, String currentUserId);
}
